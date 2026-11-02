"""expcnn 的 NumPy 反向传播与 adam 训练。

训练目标是对齐后的 RX - TX，即 CH_SEL=1 将要减掉的失真项。
输入/目标均传原始计数，内部只除以固定 32768；不按峰值缩放、不去 DC。
批次保留左右各 24 点上下文，尾批不丢弃。训练/验证分开报告。
本文件不自动生成模型、图片、日志；模型保存由上位机可选代码块控制。
"""
import numpy as np
from data_process import complex_vector, nmse_db, IQ_SCALE
from expcnn_final import expcnn, CONTEXT


def loss_and_gradients(model, x, target, valid=None):
    """x/target 为 Q1.15 浮点。梯度用 dL/dReal + j*dL/dImag 表示。"""
    prediction, c = model.forward(x, cache=True)
    target = complex_vector(target)
    if target.shape != prediction.shape:
        raise ValueError('训练输入与目标长度不同')
    if valid is None:
        valid = np.ones(len(x), dtype=bool)
    valid = np.asarray(valid, dtype=bool)
    if valid.shape != prediction.shape or not valid.any():
        raise ValueError('有效训练样本掩码不正确')
    residual = prediction - target
    loss = float(np.mean(abs(residual[valid])**2))
    go = 2 * residual * valid / valid.sum()
    p = model.parameters
    g = {}
    g['L3_w'] = np.sum(go[:, None] * c['l2'].conj(), axis=0).reshape(7, 1)
    g['L3_bias'] = np.array([[go.sum()]])
    gz = go[:, None] * p['L3_w'][:, 0].conj()
    gr = gz.real[:, :, None] * c['weighted'].real + gz.imag[:, :, None] * c['weighted'].imag
    grr = gr * c['radial']
    g['L2_c'] = np.sum(grr * 2 * abs(p['L2_theta']) * c['delta'], axis=0)
    g['L2_theta'] = np.sum(-grr * c['delta']**2 * np.sign(p['L2_theta']), axis=0)
    g['L2_w'] = np.empty_like(p['L2_w'])
    g['L2_w'][::2] = np.sum(gz.real[:, :, None] * c['radial'] * c['taps'].real, axis=0)
    g['L2_w'][1::2] = np.sum(gz.imag[:, :, None] * c['radial'] * c['taps'].imag, axis=0)
    radius_gradient = np.sum(-2 * grr * abs(p['L2_theta']) * c['delta'], axis=2)
    gl1 = radius_gradient * c['l1'] / np.maximum(c['radius'], 1e-15)
    gt = (gz.real[:, :, None] * c['radial'] * p['L2_w'][::2]
          + 1j*gz.imag[:, :, None] * c['radial'] * p['L2_w'][1::2])
    # taps[n,j] = L1[n+j-4]；反向散加，不在边界循环移位。
    n = len(x)
    for j in range(9):
        shift = j - 4
        start, stop = max(0, -shift), min(n, n - shift)
        gl1[start + shift:stop + shift] += gt[start:stop, :, j]
    g['L1_w'] = gl1.T @ c['windows'].conj()
    g['L1_bias'] = gl1.sum(axis=0, keepdims=True)
    return loss, prediction, g


class adam:
    """复数实部、虚部分别维护一阶和二阶矩；执行梯度下降。"""
    def __init__(self, parameters, lr=.005, beta1=.9, beta2=.999, eps=1e-8):
        if not np.isfinite(lr) or lr <= 0:
            raise ValueError('lr 必须为正数')
        self.parameters, self.lr = parameters, lr
        self.beta1, self.beta2, self.eps, self.t = beta1, beta2, eps, 0
        self.m = {k: np.zeros_like(v) for k, v in parameters.items()}
        self.v = {k: np.zeros_like(v) for k, v in parameters.items()}

    def step(self, gradients):
        self.t += 1
        for name, a in self.parameters.items():
            grad = gradients[name]
            parts = ('real', 'imag') if np.iscomplexobj(a) else ('real',)
            for part in parts:
                ap, gp = getattr(a, part), getattr(grad, part)
                mp, vp = getattr(self.m[name], part), getattr(self.v[name], part)
                mp[...] = self.beta1 * mp + (1 - self.beta1) * gp
                vp[...] = self.beta2 * vp + (1 - self.beta2) * gp**2
                ap[...] -= self.lr * (mp / (1 - self.beta1**self.t)) / (
                    np.sqrt(vp / (1 - self.beta2**self.t)) + self.eps)


def train_model(x_counts, target_counts, model=None, iters=300, lr=.005,
                gamma=.995, batch_size=1024, validation_fraction=.2,
                seed=48, report_every=10):
    """返回最佳验证模型和 history；可传上轮 model 继续训练。

    最后 validation_fraction 的连续样本用于验证，分界两边各隔离 24 点。
    不随机打散时间样本；批次前向包含 24 点 halo，仅在批次核心计算损失。
    history 存在内存，可在 Spyder/VS Code 变量窗口检查。
    """
    x, y = complex_vector(x_counts) / IQ_SCALE, complex_vector(target_counts) / IQ_SCALE
    if x.shape != y.shape or len(x) < 256:
        raise ValueError('训练数据须等长且至少 256 点')
    if not isinstance(iters, int) or iters < 1 or not isinstance(batch_size, int) or batch_size < 1:
        raise ValueError('iters、batch_size 必须为正整数')
    if not 0 < validation_fraction < .5 or not 0 < gamma <= 1 or report_every < 1:
        raise ValueError('检查 validation_fraction、gamma、report_every')
    split = int(len(x) * (1 - validation_fraction))
    train_start, train_stop = CONTEXT, split - CONTEXT
    val_start, val_stop = split + CONTEXT, len(x) - CONTEXT
    if train_stop <= train_start or val_stop <= val_start:
        raise ValueError('分开训练/验证并保留上下文后样本不足，请增加采样长度')
    model = expcnn(seed=seed) if model is None else expcnn(model.parameters)
    model.project_parameters()
    optimizer = adam(model.parameters, lr=lr)
    prediction = model.forward(x)
    best_score = nmse_db(prediction[val_start:val_stop], y[val_start:val_stop])
    best_parameters = {k: v.copy() for k, v in model.parameters.items()}
    history = [dict(iteration=0,
                    train_nmse=nmse_db(prediction[train_start:train_stop], y[train_start:train_stop]),
                    val_nmse=best_score, lr=lr)]
    print(f'初始 train={history[0]["train_nmse"]:.2f} dB, val={best_score:.2f} dB')
    try:
        for iteration in range(1, iters + 1):
            for start in range(train_start, train_stop, batch_size):
                stop = min(start + batch_size, train_stop)
                left, right = max(0, start - CONTEXT), min(len(x), stop + CONTEXT)
                mask = np.zeros(right - left, dtype=bool)
                mask[start - left:stop - left] = True
                loss, _, gradients = loss_and_gradients(model, x[left:right], y[left:right], mask)
                if not np.isfinite(loss) or not all(np.isfinite(g).all() for g in gradients.values()):
                    raise FloatingPointError('训练出现非有限数，请降低学习率并检查 RX')
                # 仅防止异常梯度；正常小误差训练不改变梯度。
                norm = np.sqrt(sum(float(np.sum(abs(g)**2)) for g in gradients.values()))
                if norm > 10:
                    gradients = {k: v * (10 / norm) for k, v in gradients.items()}
                optimizer.step(gradients)
                model.project_parameters()
            optimizer.lr *= gamma
            prediction = model.forward(x)
            train_score = nmse_db(prediction[train_start:train_stop], y[train_start:train_stop])
            val_score = nmse_db(prediction[val_start:val_stop], y[val_start:val_stop])
            history.append(dict(iteration=iteration, train_nmse=train_score,
                                val_nmse=val_score, lr=optimizer.lr))
            if val_score < best_score:
                best_score = val_score
                best_parameters = {k: v.copy() for k, v in model.parameters.items()}
            if iteration == 1 or iteration % report_every == 0 or iteration == iters:
                print(f'{iteration}/{iters}: train={train_score:.2f} dB, val={val_score:.2f} dB')
    except KeyboardInterrupt:
        print('训练已中断，返回目前验证误差最低的完整模型')
    print(f'采用最佳验证模型：val={best_score:.2f} dB')
    return expcnn(best_parameters), history


# %% 独立训练调用示例（x_train、err_train 为上位机接收后准备的复数计数）
# model, history = train_model(x_train, err_train, iters=300, lr=.005)
# y_pred = model.predict(x_train)
# model.save('model_para.mat')  # 需要保存时再显式执行

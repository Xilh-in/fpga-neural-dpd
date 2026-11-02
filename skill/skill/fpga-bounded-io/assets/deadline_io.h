/* Portable polling/staged receive skeleton. Integrator supplies timer and IO callbacks. */
#ifndef SKILL_DEADLINE_IO_H
#define SKILL_DEADLINE_IO_H
#include <stdint.h>
#include <stddef.h>
typedef uint64_t (*skill_now_fn)(void *context);
typedef int (*skill_ready_fn)(void *context);
typedef uint8_t (*skill_byte_fn)(void *context);
typedef uint32_t (*skill_status_fn)(void *context);

/* budgets are in the caller's timer ticks, not assumed milliseconds. */
static inline int skill_receive_staged(void *context, skill_now_fn now,
    skill_ready_fn ready, skill_byte_fn get_byte, uint8_t *staging,
    size_t size, size_t capacity, uint64_t total_budget, uint64_t silence_budget)
{
    size_t i = 0;
    uint64_t start, last, current;
    if (!staging || size > capacity || !total_budget || !silence_budget) return 0;
    start = last = now(context);
    while (i < size) {
        current = now(context);
        if (current - start >= total_budget || current - last >= silence_budget) return 0;
        if (ready(context)) { staging[i++] = get_byte(context); last = current; }
    }
    return 1; /* Commit staging to hardware only AFTER this success return. */
}

static inline int skill_poll_status(void *context, skill_now_fn now,
    skill_status_fn read_status, uint32_t expected, uint64_t budget)
{
    uint64_t start = now(context);
    if (!budget) return 0;
    while (now(context) - start < budget)
        if (read_status(context) == expected) return 1;
    return 0; /* Caller clears controls and returns to its command loop. */
}
#endif

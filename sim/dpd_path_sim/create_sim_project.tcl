# Vivado 2025.2: source this from a fresh GUI window (no project open).
# Creates a separate simulation project; no implementation project is modified.
if {[llength [get_projects -quiet]] != 0} {
    error "Open a new Vivado window without a project, then source this script."
}
set kit_root [file dirname [file normalize [info script]]]
set sim_dir [file join $kit_root simulation]
set project_dir [file join $kit_root work [clock format [clock seconds] -format {%Y%m%d_%H%M%S}]]
set suffix 0
set base_dir $project_dir
while {[file exists $project_dir]} {
    incr suffix
    set project_dir ${base_dir}_$suffix
}
create_project dpd_path_sim $project_dir -part xc7z100ffg900-2
set_property target_language Verilog [current_project]
set design_files [concat [glob [file join $kit_root rtl dpd_ip_v1 *.v]] [glob [file join $kit_root rtl dpd_ip_v1 *.sv]]]
add_files -norecurse $design_files
set_property file_type SystemVerilog [get_files $design_files]
set_property top data_ctrl [get_filesets sources_1]
add_files -fileset sim_1 -norecurse [file join $kit_root tb_tx_model_path.sv]
set_property top tb_tx_model_path [get_filesets sim_1]
set_property generic [list [format {SIM_DIR="%s"} $sim_dir]] [get_filesets sim_1]
set_property target_simulator XSim [current_project]
set_property xsim.simulate.runtime all [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "PATH_SIM_PROJECT_READY"
puts "PROJECT_DIR=$project_dir"
puts "SIM_DIR=$sim_dir"
puts "Next: Run Simulation -> Run Behavioral Simulation."

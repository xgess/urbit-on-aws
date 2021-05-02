resource "local_file" "setup_nginx" {
  filename = "${var.rendered_scripts_path}/setup_nginx.sh"
  content = templatefile("${path.module}/scripts/setup_nginx.sh.tpl", {
    DOMAIN   = var.domain
    USERNAME = local.instance_username
  })
  file_permission = "0755"
}

resource "local_file" "start_urbit" {
  filename = "${var.rendered_scripts_path}/start_urbit.sh"
  content = templatefile("${path.module}/scripts/start_urbit.sh.tpl", {
    USERNAME          = local.instance_username
    SHIP              = var.ship
    TMUX_SESSION_NAME = var.tmux_session_name
  })
  file_permission = "0755"
}

resource "local_file" "stop_urbit" {
  filename = "${var.rendered_scripts_path}/stop_urbit.sh"
  content = templatefile("${path.module}/scripts/stop_urbit.sh.tpl", {
    TMUX_SESSION_NAME = var.tmux_session_name
  })
  file_permission = "0755"
}

output "scripts" {
  value = [
    local_file.setup_nginx.filename,
    local_file.start_urbit.filename,
    local_file.stop_urbit.filename,
  ]
}


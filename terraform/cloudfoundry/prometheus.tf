resource "aws_lb" "prometheus" {
  name               = "${var.env}-prometheus"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.prometheus-lb.id}"]
  subnets            = ["${split(",", var.infra_subnet_ids)}"]
}

resource "aws_security_group" "prometheus-lb" {
  name_prefix = "${var.env}-prometheus-lb-"
  description = "Prometheus LB security group"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${compact(var.admin_cidrs)}",
    ]
  }

  tags {
    Name = "${var.env}-prometheus-lb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "p8s_alertmanager_target_group" {
  value = "${aws_lb_target_group.p8s_alertmanager.name}"
}

resource "aws_lb_target_group" "p8s_alertmanager" {
  name     = "${var.env}-p8s-alertmanager"
  port     = 9093
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    matcher = "200-499"
  }
}

output "p8s_grafana_target_group" {
  value = "${aws_lb_target_group.p8s_grafana.name}"
}

resource "aws_lb_target_group" "p8s_grafana" {
  name     = "${var.env}-p8s-grafana"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    matcher = "200-499"
  }
}

output "p8s_prometheus_target_group" {
  value = "${aws_lb_target_group.p8s_prometheus.name}"
}

resource "aws_lb_target_group" "p8s_prometheus" {
  name     = "${var.env}-p8s-prometheus"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    matcher = "200-499"
  }
}

resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = "${aws_lb.prometheus.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "${var.default_elb_security_policy}"
  certificate_arn   = "${data.aws_acm_certificate.system.arn}"

  # FIXME: use a fixed-response 404 when we've upgraded to a version of the AWS
  # provider that supports this (1.6 does not).
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.p8s_grafana.arn}"
  }
}

resource "aws_lb_listener_rule" "p8s_alertmanager" {
  listener_arn = "${aws_lb_listener.prometheus.arn}"
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.p8s_alertmanager.arn}"
  }

  condition {
    field  = "host-header"
    values = ["alertmanager.*"]
  }
}

resource "aws_lb_listener_rule" "p8s_grafana" {
  listener_arn = "${aws_lb_listener.prometheus.arn}"
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.p8s_grafana.arn}"
  }

  condition {
    field  = "host-header"
    values = ["grafana.*"]
  }
}

resource "aws_lb_listener_rule" "p8s_prometheus" {
  listener_arn = "${aws_lb_listener.prometheus.arn}"
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.p8s_prometheus.arn}"
  }

  condition {
    field  = "host-header"
    values = ["prometheus.*"]
  }
}

resource "aws_route53_record" "alertmanager" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "alertmanager.${var.system_dns_zone_name}."
  type    = "A"

  alias {
    name                   = "${aws_lb.prometheus.dns_name}"
    zone_id                = "${aws_lb.prometheus.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "grafana.${var.system_dns_zone_name}."
  type    = "A"

  alias {
    name                   = "${aws_lb.prometheus.dns_name}"
    zone_id                = "${aws_lb.prometheus.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "prometheus" {
  zone_id = "${var.system_dns_zone_id}"
  name    = "prometheus.${var.system_dns_zone_name}."
  type    = "A"

  alias {
    name                   = "${aws_lb.prometheus.dns_name}"
    zone_id                = "${aws_lb.prometheus.zone_id}"
    evaluate_target_health = false
  }
}
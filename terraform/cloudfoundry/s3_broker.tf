resource "aws_elb" "s3_broker" {
  name                      = "${var.env}-s3-broker"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"
  internal                  = true
  security_groups           = ["${aws_security_group.service_brokers.id}"]

  access_logs {
    bucket        = "${aws_s3_bucket.elb_access_log.id}"
    bucket_prefix = "cf-broker-s3"
    interval      = 5
  }

  health_check {
    target              = "HTTP:80/healthcheck"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.system.arn}"
  }
}

resource "aws_lb_ssl_negotiation_policy" "s3_broker" {
  name          = "paas-${var.default_elb_security_policy}"
  load_balancer = "${aws_elb.s3_broker.id}"
  lb_port       = 443

  attribute {
    name  = "Reference-Security-Policy"
    value = "${var.default_elb_security_policy}"
  }
}

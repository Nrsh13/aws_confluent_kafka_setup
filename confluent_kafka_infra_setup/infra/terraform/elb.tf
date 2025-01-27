# Resources for Control Center Load Balancer

## Elastic Load Balancer for Control Center
resource "aws_lb" "control_center_lb" {
  name               = "${var.component}-${var.environment}-control-center-elb"
  internal           = var.load_balancer_is_internal
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ec2_server_sg.id}"]
  subnets            = data.aws_subnets.subnet_ids.ids
  enable_deletion_protection = false

  tags = merge(var.common_tags, var.specific_tags, {
    Name = "${var.component}-${var.environment}-control-center-elb"
  })
}

## Target Group for Control Center (port 9021)
resource "aws_lb_target_group" "control_center_target_group" {
  name     = "${var.component}-${var.environment}-control-center-tg"
  port     = 9021
  protocol = "HTTPS"
  vpc_id   = "${data.aws_vpc.current_vpc.id}"

  health_check {
    interval            = 30
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, var.specific_tags, {
    Name = "${var.component}-${var.environment}-control-center-tg"
  })
}

## Load Balancer Listener for Control Center
resource "aws_lb_listener" "control_center_listener" {
  load_balancer_arn = aws_lb.control_center_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.issued[0].arn}"

  default_action {
    target_group_arn    = "${aws_lb_target_group.control_center_target_group.arn}"
    type                = "forward"
  }
}

## Target Group Attachment for Control Center
resource "aws_lb_target_group_attachment" "control_center_attachment" {
  count               = min(var.instance_count, 2)  # Limit to the first 2 instances
  target_group_arn    = aws_lb_target_group.control_center_target_group.arn
  target_id           = aws_instance.my_ec2_instances[count.index].id
  port                = 9021
}

## Route 53 Record for Control Center
resource "aws_route53_record" "control_center_record" {
  zone_id = var.route53_hosted_zone
  name    = "control-center.${var.route53_hosted_zone_dns}"
  type    = "A"

  alias {
    name                   = aws_lb.control_center_lb.dns_name
    zone_id                = aws_lb.control_center_lb.zone_id
    evaluate_target_health = true
  }
}

# Resources for SR UI Load Balancer

## Elastic Load Balancer for SR UI
resource "aws_lb" "sr_lb" {
  name               = "${var.component}-${var.environment}-sr-elb"
  internal           = var.load_balancer_is_internal
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ec2_server_sg.id}"]
  subnets            = data.aws_subnets.subnet_ids.ids

  enable_deletion_protection = false

  tags = merge(var.common_tags, var.specific_tags, {
    Name = "${var.component}-${var.environment}-sr-elb"
  })
}

## Target Group for SR UI (port 18081)
resource "aws_lb_target_group" "sr_target_group" {
  name     = "${var.component}-${var.environment}-sr-tg"
  port     = 18081
  protocol = "HTTPS"
  vpc_id   = "${data.aws_vpc.current_vpc.id}"

  health_check {
    interval            = 30
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, var.specific_tags, {
    Name = "${var.component}-${var.environment}-sr-tg"
  })
}

## Load Balancer Listener for SR UI
resource "aws_lb_listener" "sr_listener" {
  load_balancer_arn = aws_lb.sr_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.issued[0].arn}"

  default_action {
    target_group_arn    = "${aws_lb_target_group.sr_target_group.arn}"
    type                = "forward"
  }
}

## Target Group Attachment for SR UI
resource "aws_lb_target_group_attachment" "sr_attachment" {
  count               = min(var.instance_count, 2)  # Limit to the first 2 instances
  target_group_arn    = aws_lb_target_group.sr_target_group.arn
  target_id           = aws_instance.my_ec2_instances[count.index].id
  port                = 18081
}

## Route 53 Record for SR UI
resource "aws_route53_record" "sr_record" {
  zone_id = var.route53_hosted_zone
  name    = "schema-registry.${var.route53_hosted_zone_dns}"
  type    = "A"

  alias {
    name                   = aws_lb.sr_lb.dns_name
    zone_id                = aws_lb.sr_lb.zone_id
    evaluate_target_health = true
  }
}

# Resources for Kafka Connect Load Balancer

## Elastic Load Balancer for Kafka Connect
resource "aws_lb" "kafka_connect_lb" {
  name               = "${var.component}-${var.environment}-kafka-connect-elb"
  internal           = var.load_balancer_is_internal
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ec2_server_sg.id}"]
  subnets            = data.aws_subnets.subnet_ids.ids

  enable_deletion_protection = false

  tags = merge(var.common_tags, var.specific_tags, {
    Name = "${var.component}-${var.environment}-kafka-connect-elb"
  })
}

## Target Group for Kafka Connect (port 18083)
resource "aws_lb_target_group" "kafka_connect_target_group" {
  name     = "${var.component}-${var.environment}-kafka-connect-tg"
  port     = 18083
  protocol = "HTTPS"
  vpc_id   = "${data.aws_vpc.current_vpc.id}"

  health_check {
    interval            = 30
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, var.specific_tags, {
    Name = "${var.component}-${var.environment}-kafka-connect-tg"
  })
}

## Load Balancer Listener for Kafka Connect
resource "aws_lb_listener" "kafka_connect_listener" {
  load_balancer_arn = aws_lb.kafka_connect_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.issued[0].arn}"

  default_action {
    target_group_arn    = "${aws_lb_target_group.kafka_connect_target_group.arn}"
    type                = "forward"
  }
}

## Target Group Attachment for Kafka Connect
resource "aws_lb_target_group_attachment" "kafka_connect_attachment" {
  count               = min(var.instance_count, 1)  # Limit to the first 2 instances
  target_group_arn    = aws_lb_target_group.kafka_connect_target_group.arn
  target_id           = aws_instance.my_ec2_instances[count.index].id
  port                = 18083
}

## Route 53 Record for Kafka Connect
resource "aws_route53_record" "kafka_connect_record" {
  zone_id = var.route53_hosted_zone
  name    = "kafka-connect.${var.route53_hosted_zone_dns}"
  type    = "A"

  alias {
    name                   = aws_lb.kafka_connect_lb.dns_name
    zone_id                = aws_lb.kafka_connect_lb.zone_id
    evaluate_target_health = true
  }
}
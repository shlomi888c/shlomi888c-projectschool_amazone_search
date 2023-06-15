resource "aws_alb" "app_alb" {
name = "app-alb"
load_balancer_type = "application"
internal = false
security_groups    = [aws_security_group.alb_5000.id]
subnets = [aws_subnet.alb_1.id, aws_subnet.alb_2.id,aws_subnet.alb_3.id]
}
resource "aws_alb_target_group" "app_alb_tr" {
name = "app-alb-tr"
port = 5000
protocol = "HTTP"
vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
}

resource "aws_alb_listener" "alb_lis" {
load_balancer_arn = "${aws_alb.app_alb.arn}"
port = "80"
protocol = "HTTP"

default_action {
type = "forward"
target_group_arn = "${aws_alb_target_group.app_alb_tr.arn}"
}
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch" {
alarm_name = "up-70%"
comparison_operator = "GreaterThanThreshold"
evaluation_periods = "1"
metric_name = "CPUUtilization"
namespace = "AWS/EC2"
period = "60"
statistic = "Average"
threshold = "70"
alarm_description = "This will trigger the scaling policy"
alarm_actions = [aws_autoscaling_policy.app_po.arn]
}


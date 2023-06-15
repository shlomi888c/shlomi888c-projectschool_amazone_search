resource "aws_autoscaling_group" "asg_app" {
  name                      = "asg-app"
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.app.name
  vpc_zone_identifier       = [aws_subnet.ec2_1.id, aws_subnet.ec2_2.id, aws_subnet.ec2_3.id]
  target_group_arns = [aws_alb_target_group.app_alb_tr.arn]
 lifecycle {
    ignore_changes = [desired_capacity, target_group_arns]
  }
}
resource "aws_autoscaling_policy" "app_po" {
name = "app-pol"
adjustment_type = "ChangeInCapacity"
autoscaling_group_name = aws_autoscaling_group.asg_app.name
scaling_adjustment = 1
}
resource "aws_autoscaling_attachment" "example" {
    autoscaling_group_name = aws_autoscaling_group.asg_app.name
    lb_target_group_arn    = "${aws_alb_target_group.app_alb_tr.arn}"
}

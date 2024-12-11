# data "aws_route53_zone" "D" {
#   name         = "leeway.live"  
# }

# data "aws_lb" "alb" {
#   name = aws_lb.alb.name
# }

# resource "aws_route53_record" "alb_dns" {
#   zone_id = data.aws_route53_zone.D.zone_id
#   name    = "www.leeway.live"  
#   type    = "A"
#   alias {
#     name                   = data.aws_lb.alb.dns_name
#     zone_id                = data.aws_lb.alb.zone_id
#     evaluate_target_health = true
#   }
# }


# 創建 Route 53 託管區
# 如果域名已註冊並管理於 Route 53，直接指定 Hosted Zone 的 ID
# 確保 "leeway.live" 是您擁有並已設置的域名

# ALB 的 DNS 記錄
resource "aws_route53_record" "alb" {
  zone_id = "Z05281272J1GJUDK0ECY9" # 替換為您的 Hosted Zone ID
  name    = "www.leeway.live" # 可根據需求調整子域名
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
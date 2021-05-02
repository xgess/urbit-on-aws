data "aws_route53_zone" "main" {
  name = "${var.domain}."
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.instance.public_ip]
}

resource "aws_route53_record" "naked" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"
  ttl     = "300"
  records = [aws_eip.instance.public_ip]
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Change to your IP for security
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}


resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "inline_policy" {
  name = "custom-inline-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "lambda:*",
          "iam:PassRole",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:DetachRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:DeleteRole",
          "apigateway:*",
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}


resource "aws_instance" "ec2" {
  ami           = "ami-03261d758437926bb" # Amazon Linux 2 in ap-south-1, update per region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  availability_zone = ap-south-1a
  #  key_name      = "your-keypair-name" # Replace with your EC2 keypair
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "myworkspace"
  }
}



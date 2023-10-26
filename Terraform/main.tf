resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro" 
  subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_instance" "checkmk_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_s3_bucket" "backup_bucket" {
  bucket = "backupdb"
}

####MongoDB#########

# Création de la base de données
resource "aws_docdb_cluster" "documentdb" {
  cluster_identifier    = "my-db-cluster"
  master_username       = ""
  master_password       = "" 
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot   = true
}

resource "aws_docdb_cluster_instance" "documentdb_instance" {
  count             = 3
  cluster_identifier = aws_docdb_cluster.documentdb.id
  instance_class    = "db.r5.large" 
  identifier         = "my-documentdb-instance-${count.index}"
}

# Configuration des groupes de sécurité
resource "aws_security_group" "documentdb_sg" {
  name_prefix = "documentdb-"
  description = "Security group for Amazon DocumentDB"
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Remplacer par bonne ip
  }
}

# Autorisations pour permettre à l'instance d'accéder à la db
resource "aws_security_group_rule" "ec2_to_documentdb" {
  type        = "ingress"
  from_port   = 27017
  to_port     = 27017
  protocol    = "tcp"
  security_group_id = aws_security_group.documentdb_sg.id
  source_security_group_id = aws_instance.ec2_instance.security_groups[0]
}
provider "aws" {
  region = "us-east-1"
  profile = "insights"
}

resource "aws_s3_bucket" "terraformrangeeyes" {
  bucket = "terraformrangeeyes"
  force_destroy = true
  tags = {
    Name = "terraformrangeeyes"
  }
}

# Upload an object
resource "aws_s3_bucket_object" "scripttogluejob" {

  bucket = aws_s3_bucket.terraformrangeeyes.id
  key    = "tf_s3-aurora-transfer-table-indicators.py"
  acl    = "private"  # or can be "public-read"

  source = "tf_s3-aurora-transfer-table-indicators.py"

  etag = filemd5("tf_s3-aurora-transfer-table-indicators.py")

}

variable "az" {
  description = "Value for Avaiability Zone"
  type        = string
  default     = "us-east-1a"
}

variable "role" {
  description = "Role that must be used to grant access for all services"
  type        = string
  default     = "orange-eyes-poc-glue-rds"
}


resource "aws_glue_connection" "tf_orange-eyes-table-indicators_connection" {
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://172.23.148.40:5432/postgres"
    PASSWORD            = "OrangeEyesP0C"
    USERNAME            = "postgres"
  }

  name = "tf_orange-eyes-table-indicators_connection"

  physical_connection_requirements {
    availability_zone      = var.az
    security_group_id_list = ["sg-0180325d6a853f497"]
    subnet_id              = "subnet-0502da75ea5f85e49"
  }
}

resource "aws_glue_catalog_database" "tf_orange-eyes-database" {
  name = "tf_orange-eyes-database"
}

resource "aws_glue_crawler" "tf_orange-eyes-table-indicators-aurora_crawler" {
  database_name = aws_glue_catalog_database.tf_orange-eyes-database.name
  name          = "tf_orange-eyes-table-indicators"
  role          = var.role

  jdbc_target {
    connection_name = aws_glue_connection.tf_orange-eyes-table-indicators_connection.name
    path            = "postgres/orange/indicators"
  }
}

resource "aws_glue_crawler" "tf_orange-eyes-bucket-indicators-s3_crawler" {
  database_name = aws_glue_catalog_database.tf_orange-eyes-database.name
  name          = "tf_orange-eyes-bucket-indicators-s3_crawler"
  role          = var.role
 

  s3_target {
    path = "s3://indicators-git-pipes/indicators"
  }
}

resource "aws_cloudwatch_log_group" "tf_orangeeyes-cloudwatch" {
  name              = "tf_orangeeyes-cloudwatch"
  retention_in_days = 14
}

resource "aws_glue_job" "tf_s3-aurora-transfer-table-indicators" {
  name     = "tf_s3-aurora-transfer-table-indicators"
  role_arn = "arn:aws:iam::629436217496:role/orange-eyes-poc-glue-rds"
  connections = [aws_glue_connection.tf_orange-eyes-table-indicators_connection.name]
  glue_version = "2.0"
  

  command {
    script_location = "s3://${aws_s3_bucket.terraformrangeeyes.bucket}/tf_s3-aurora-transfer-table-indicators.py"
    python_version = "3"
  }

  default_arguments = {
    "--job-language" = "Python 3"
    "--glue_version" = "2.0"
    "--worker_type" = "G.1X"
    "--number_of_workers" = "10"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.tf_orangeeyes-cloudwatch.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
  }
}

resource "aws_glue_workflow" "tf_orange-eyes-workflow" {
  name = "tf_orange-eyes-workflow"
}

resource "aws_glue_trigger" "tf_orange-eyes-start-trigger" {
  name          = "tf_orange-eyes-start-trigger"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.tf_orange-eyes-workflow.name

  actions {
    crawler_name = aws_glue_crawler.tf_orange-eyes-bucket-indicators-s3_crawler.name
  }

  actions {
    crawler_name = aws_glue_crawler.tf_orange-eyes-table-indicators-aurora_crawler.name
  }
}

resource "aws_glue_trigger" "tf_orange-eyes-job-trigger" {
  name = "tf_orange-eyes-job-trigger"
  type = "CONDITIONAL"
  workflow_name = aws_glue_workflow.tf_orange-eyes-workflow.name

  actions {
    job_name = aws_glue_job.tf_s3-aurora-transfer-table-indicators.name
  }

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.tf_orange-eyes-bucket-indicators-s3_crawler.name
      crawl_state  = "SUCCEEDED"
    }

    conditions {
      crawler_name = aws_glue_crawler.tf_orange-eyes-table-indicators-aurora_crawler.name
      crawl_state  = "SUCCEEDED"
    }
  }
}
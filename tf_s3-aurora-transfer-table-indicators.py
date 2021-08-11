import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
## @type: DataSource
## @args: [database = "tf_orange-eyes-database", table_name = "indicators", transformation_ctx = "DataSource0"]
## @return: DataSource0
## @inputs: []
DataSource0 = glueContext.create_dynamic_frame.from_catalog(database = "tf_orange-eyes-database", table_name = "indicators", transformation_ctx = "DataSource0")
## @type: ApplyMapping
## @args: [mappings = [("project_obj", "string", "pk", "string"), ("event_day", "date", "event_date", "date"), ("failed", "long", "failed", "long"), ("success", "long", "success", "long"), ("success_failed_rate", "double", "success_failed_rate", "double"), ("canceled", "long", "canceled", "long"), ("running", "long", "running", "long"), ("created", "long", "created", "long"), ("pending", "long", "pending", "long"), ("all", "long", "total", "long")], transformation_ctx = "Transform0"]
## @return: Transform0
## @inputs: [frame = DataSource0]
Transform0 = ApplyMapping.apply(frame = DataSource0, mappings = [("project_obj", "string", "pk", "string"), ("event_day", "date", "event_date", "date"), ("failed", "long", "failed", "long"), ("success", "long", "success", "long"), ("success_failed_rate", "double", "success_failed_rate", "double"), ("canceled", "long", "canceled", "long"), ("running", "long", "running", "long"), ("created", "long", "created", "long"), ("pending", "long", "pending", "long"), ("all", "long", "total", "long")], transformation_ctx = "Transform0")
## @type: DataSink
## @args: [database = "tf_orange-eyes-database", table_name = "postgres_orange_indicators", transformation_ctx = "DataSink0"]
## @return: DataSink0
## @inputs: [frame = Transform0]
DataSink0 = glueContext.write_dynamic_frame.from_catalog(frame = Transform0, database = "tf_orange-eyes-database", table_name = "postgres_orange_indicators", transformation_ctx = "DataSink0")
job.commit()
Data mining
Final Proyect

Team members: Lorena Mejía, Alfredo Carrillo, Ricardo Figueroa

Requisites:
1. python3

To automatically download data from the contest, the following actions must be followed:

1. Install kaggle's CLI with the command `sudo pip3 install kaggle` 
3. Make an API token from kaggle by visting your profile at the url `https://www.kaggle.com/[USER]/account` and save at your own directory @ `~/.kaggle/kaggle.json`
4. For security purposes, execute the following command to change the .json file token permissions `chmod 600 /home/ricardo/.kaggle/kaggle.json`
5. Run the command `kaggle competitions download -c kkbox-churn-prediction-challenge`.
6. After all these steps and also after receiving the data from the Kaggle interface, there is a need to unzip the received files with the following command `unzip all.zip -d .`
7. All the unziped files are presented in format '7z', so there is the need to decompress them by executing the following script: `./descomprimir.sh`. This script will also move all the `.csv` files to the `./data` and remove all the `7z` files to clean the directory.

After we downloaded and decompressed the files, we applied the following functions in order to format the tables (all the procedure can be found in the jupyter notebook)

1. `user_logs = sc.textFile('./data/user_logs.csv') \
    .map(lambda line: line.split(","))
user_logs=user_logs.toDF(user_logs.first())
user_logs = user_logs.rdd.zipWithIndex().filter(lambda row_index: row_index[1] > 0).keys().toDF()` 
2. Then we applied a map function to modify the format of dates:

`user_logs_clean_date = user_logs.withColumn("date", trans_date_udf("date"))`

Once we had a formatted tables (with the proper date format for spark), we made a "manageable table" for the machine learning summarizing the user_logs and transactions tables. We considered the las 15 records of logs and last 5 records of transactions and averaged them with a grouping of the user id.

Instructions to set cluster in Spark

We are dealing with Big Data in this proyect, so we chose to use EMR, Spark on Hadoop and S3 (to store the files).
	- 1 master and 2 slaves (t2.large instances).

The instructions to creating a cluster can be found in `http://holowczak.com/getting-started-with-apache-spark-on-aws/5/`. Here it is important to mention that it is required to modify the security configuration and to add open SSH protocol in order to connect with the master.

The command to connect with the cluster is `ssh -i /home/ricardo/Desktop/my-ec2-key-pair.pem hadoop@ec2-18-224-25-219.us-east-2.compute.amazonaws.com`, replace `my-ec2-key` with the proper key.

We created an RDD and data frame with the following commands in order to make a summary average of the top 15 most recent user logs:

`val sqlContext = new org.apache.spark.sql.SQLContext(sc)`

`val df = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/user_logs").toDF("msno", "date", "num_25", "num_50", "num_75", "num_985", "num_100", "num_unq", "total_secs")`

The same for the table "transactions"

`val df_transactions = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/transactions").toDF("msno", "payment_method_id", "payment_plan_days", "plan_list_price", "actual_amount_paid", "is_auto_renew", "transaction_date", "membership_expire_date", "is_cancel")`

For members csv:
`val df_members = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/members").toDF("msno", "city", "bd", "gender", "registered_via", "registered_init_time")`

For train data:
`val df_train = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/train").toDF("msno", "is_churn")`

For test data:
`val df_test = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/test").toDF("msno", "is_churn")`


`import org.apache.spark.sql.functions.{row_number, max, broadcast}`

`import org.apache.spark.sql.expressions.Window`

`val w = Window.partitionBy($"msno").orderBy($"date".desc)`

For transactions
`val w_t = Window.partitionBy($"msno").orderBy($"transaction_date".desc)`

`val dfTop15 = df.withColumn("rn", row_number.over(w)).where($"rn" <= 15).drop("rn")`

`val dfTop_transaction = df_transactions.withColumn("rn", row_number.over(w_t)).where($"rn" == 15).drop("rn")`

`val avg_dfTop15 = dfTop15.groupBy($"msno").agg(avg($"num_25").as("avg_num_25"),avg($"num_50").as("avg_num_50"), avg($"num_75").as("avg_num_75"), avg($"num_985").as("avg_num_985"), avg($"num_100").as("avg_num_100"), avg($"num_unq").as("avg_num_unq"), avg($"total_secs").as("total_secs"))`

For transactions
val avg_dfTop5 = dfTop_transaction.groupBy($"msno").agg(avg($"payment_method_id").as("payment_method_id"),avg($"payment_plan_days").as("payment_plan_days"), avg($"plan_list_price").as("plan_list_price"), avg($"actual_amount_paid").as("actual_amount_paid"), avg($"is_auto_renew").as("is_auto_renew"), avg($"transaction_date").as("transaction_date"), avg($"membership_expire_date").as("membership_expire_date"),avg($"is_cancel").as("is_cancel"))

In order to write to S3: 
`dfTop15.coalesce(1).write.format("com.databricks.spark.csv").option("header", "true").save("s3://proyectomineria/data/resumen_logs")`

For transactions:
`dfTop_transaction.coalesce(1).write
.format("com.databricks.spark.csv")
.option("header", "true")
.save("s3://proyectomineria/data/resumen_transactions")`

The command to join the summary dataframes is the following:

Join train table with members:

`val joinedDF1 = df_train.as('a).join(df_members.as('b),$"a.msno" === $"b.msno")`


Join joined table (members with train) with summary-average logs table

`val joinedDF2 = joinedDF1.join(df_avg_logs,joinedDF1("a.msno")===df_avg_logs("msno"))`

Join joinedDF2 table with summary transacions table:

`val joinedDF3 = joinedDF2.join(avg_dfTop5,joinedDF1("a.msno")===avg_dfTop5("msno"))`

Once we have the joined tables, we need to drop ducplicate columns by executing 

`val joinedDF8 = joinedDF3.select("a.msno", "is_churn", "city", "bd", "gender", "registered_via", "registered_init_time", "date", "num_25", "num_50", "num_75", "num_985", "num_100", "num_unq", "total_secs", "payment_method_id", "payment_plan_days", "plan_list_price", "actual_amount_paid", "is_auto_renew", "transaction_date", "membership_expire_date", "is_cancel")
`

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

`import org.apache.spark.sql.functions.{row_number, max, broadcast}`

`import org.apache.spark.sql.expressions.Window`

`val w = Window.partitionBy($"msno").orderBy($"date".desc)`

For transactions
`val w_t = Window.partitionBy($"msno").orderBy($"transaction_date".desc)`

import test

`val df_test = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/test/sample_submission_zero.csv").toDF("msno", "is_churn")`


import train
`val df_train = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/train/train.csv").toDF("msno", "is_churn")`

import user logs

`val df_user_logs = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/user_logs").toDF("msno", "date", "num_25", "num_50", "num_75", "num_985", "num_100", "num_unq", "total_secs")`

import members

`val df_members = sqlContext.read.format("com.databricks.spark.csv").option("header", "false").option("inferSchema", "true").load("s3://proyectomineria/data/members").toDF("msno", "city", "bd", "gender", "registered_via", "registered_init_time")`

order user_logs
`import org.apache.spark.sql.functions.{row_number, max, broadcast}`
`import org.apache.spark.sql.expressions.Window`
`val w = Window.partitionBy($"msno").orderBy($"date".desc)`
`val dfTop15_user_logs = df_user_logs.withColumn("rn", row_number.over(w)).where($"rn" <= 15).drop("rn")`

average user logs
`val dfTop15_user_logs_avg = dfTop15_user_logs.groupBy($"msno").agg(avg($"date").as("date") ,avg($"num_25").as("avg_num_25"),avg($"num_50").as("avg_num_50"), avg($"num_75").as("avg_num_75"), avg($"num_985").as("avg_num_985"), avg($"num_100").as("avg_num_100"), avg($"num_unq").as("avg_num_unq"), avg($"total_secs").as("total_secs"))`

order transactions

`val dfTop_transaction = df_transactions.withColumn("rn", row_number.over(w_t)).where($"rn" <= 1).drop("rn")`

Joins

Train + Members
`joinedDF1_members = df_train.as('a).join(df_members.as('b),$"a.msno" === $"b.msno")`
row count= 877,161

(Train + Members) + Average Logs
`val joinedDF2_train_members_logs = joinedDF1_members.join(dfTop15_user_logs_avg,joinedDF1_members("a.msno")===dfTop15_user_logs_avg("msno"))`
row count = 869,880

(Train + Members) + Average Logs + transactions
`val joinedDF3_train_members_logs_transactions = joinedDF2_train_members_logs.join(dfTop_transaction,joinedDF2_train_members_logs("a.msno")===dfTop_transaction("msno"))`
row count = 869,880

val joinedDF_train_test = joinedDF3_train_members_logs_transactions.select("avg_num_unq", "b.bd", "payment_plan_days", "a.msno", "b.city", "avg_num_50", "b.registered_init_time", "avg_num_75", "plan_list_price", "actual_amount_paid", "avg_num_25", "avg_num_100", "membership_expire_date", "a.is_churn", "is_auto_renew", "payment_method_id", "b.registered_via", "avg_num_985", "b.gender", "total_secs", "is_cancel", "transaction_date")

`joinedDF_final_train.coalesce(1).write.format("com.databricks.spark.csv").option("header", "true").save("s3://proyectomineria/data/resumen_final_train")`




Test + Members
`val joinedDF1_members_test = df_test.as('a).join(df_members.as('b),$"a.msno" === $"b.msno")`
row count = 860,967

(Test + Members) + Average Logs
`val joinedDF2_test_members_logs = joinedDF1_members_test.join(dfTop15_user_logs_avg,joinedDF1_members_test("a.msno")===dfTop15_user_logs_avg("msno"))`

(Test + Members) + Average Logs + transactions
`val joinedDF3_test_members_logs_transactions = joinedDF2_test_members_logs.join(avg_dfTop5,joinedDF2_test_members_logs("a.msno")===avg_dfTop5("msno"))`

row count = 849762

`val joinedDF_final_test = joinedDF3_test_members_logs_transactions.select("avg_num_unq", "date", "b.bd", "payment_plan_days", "b.city", "avg_num_50", "b.registered_init_time", "msno", "avg_num_75", "plan_list_price", "actual_amount_paid", "avg_num_25", "avg_num_100", "membership_expire_date", "a.is_churn", "is_auto_renew", "payment_method_id", "b.registered_via", "avg_num_985", "b.gender", "total_secs", "is_cancel", "transaction_date")`

`joinedDF_final_test.coalesce(1).write.format("com.databricks.spark.csv").option("header", "true").save("s3://proyectomineria/data/resumen_final_test")`
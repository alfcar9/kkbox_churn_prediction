from flask import Flask, url_for, jsonify, request, json

import pickle
import numpy as np
import h2o

# Para probarlo, ejecutar el siguiente comando en bash (borrar los #)
#
#curl -H "Content-type: application/json" -X POST http://localhost:5000/ -d '{"input": ____ }'
#[[6,31,'female' ,9,'2008-04-17T00:00:00.000Z',1.48764e+09,1.26667,0.466667,0.333333,1.86667 ,281.667 ,15 ,48663 ,36,30,180,180,1 ,1.4844e+09 ,'nan',0,0,0,6 ]]
#[5.73333, 0.933333, 0.733333, 0.666667, 6.46667, 13.0667, 1978.66]


h2o.init()

model = h2o.load_model('/home/lorena/Documents/mineria/proyecto/GBM_model_python_1545331842912_2112')

app = Flask(__name__)

@app.route('/', methods=['POST']) 
def predict(): 
	if request.headers['Content-Type'] == 'application/json':
		input=request.json['input']
	results = {} 
	predictors = ["city", "bd", "gender", "registered_via", "registered_init_time", "date", "num_25", "num_50", "num_75", "num_985", "num_100", "num_unq", "total_secs","payment_method_id", "payment_plan_days", "plan_list_price", "actual_amount_paid", "is_auto_renew", "transaction_date", "membership_expire_date","is_cancel", "discount", "is_discount", "amount_per_day"] 
	y_hat = model.predict(h2o.H2OFrame(input,column_names=predictors))
	results['parameters']= input
	results['resultado'] = list(y_hat.as_data_frame().p1)
	return jsonify(results)

if __name__ == '__main__':
	app.run()


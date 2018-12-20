from flask import Flask, url_for, jsonify, request, json

import pickle
import numpy as np
import h2o

# Para probarlo, ejecutar el siguiente comando en bash (borrar los #)
#
#curl -H "Content-type: application/json" -X POST http://localhost:5000/ -d '{"input":[[6.1, 3.0 , 4.6, 1.4],
#	[6.1, 2.9, 4.7, 1.4], 
#	[6.3, 2.9, 5.6, 1.8],
#	[4.6, 3.4, 1.4, 0.3],
#    [5.2, 2.7, 3.9, 1.4]]}'
#[1, 25, 7, '2014-07-14T00:00:00.000Z', 1.48398e+09, 5.73333, 0.933333, 0.733333, 0.666667, 6.46667, 13.0667, 1978.66, 41, 30, 149, 149, 1, 1.48162e+09, 0, 0, 0, 0, 4.96667]
#[5.73333, 0.933333, 0.733333, 0.666667, 6.46667, 13.0667, 1978.66]
#curl -H "Content-type: application/json" -X POST http://localhost:5000/ -d '{"input":[[5.73333, 0.933333, 0.733333, 0.666667, 6.46667, 13.0667, 1978.66], [5.73333, 0.933333, 0.733333, 0.666667, 6.46667, 13.0667, 1978.66]}'

h2o.init()

model = h2o.load_model('/home/lorena/Documents/mineria/proyecto/GBM_model_python_1545325712532_687')

app = Flask(__name__)

@app.route('/', methods=['POST']) 
def predict(): 
	if request.headers['Content-Type'] == 'application/json':
		input=request.json['input']
	results = {} 
	y_hat = model.predict(h2o.H2OFrame(list(input),column_names=["num_25", "num_50", "num_75", "num_985", "num_100", "num_unq", "total_secs"] ))
	results['parameters']= input
	results['resultado'] = y_hat.tolist() 
	return jsonify(results)

if __name__ == '__main__':
	app.run()


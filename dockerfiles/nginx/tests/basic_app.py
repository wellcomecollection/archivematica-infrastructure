#!/usr/bin/env python
# -*- encoding: utf-8

import os

from flask import Flask, jsonify, redirect

app = Flask(__name__)


@app.route("/")
def index():
    return jsonify({
        "name": os.environ["NAME"],
        "path": request.path,
    })


@app.route("/foo")
def redirect():
    return flask.redirect("/bar", code=302)


@app.route("/bar")
def redirect_target():
    return jsonify({
        "name": os.environ["NAME"],
        "path": request.path,
        "from_redirect": True
    })


app.run(host="0.0.0.0", port=int(os.environ["PORT"]))
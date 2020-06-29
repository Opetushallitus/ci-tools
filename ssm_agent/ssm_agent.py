#!/usr/bin/env python3
import boto3
import os
import psutil
import requests
import subprocess
import time
from flask import Flask, jsonify
from werkzeug.exceptions import HTTPException

client = boto3.client('ssm', region_name='eu-west-1')
app = Flask(__name__)
metadata_uri = os.environ['ECS_CONTAINER_METADATA_URI_V4']


def check_agent_status():
    for process in psutil.process_iter():
        try:
            if 'amazon-ssm-agent' in process.name().lower():
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return False


def describe_container_managed_instance(managed_instance_name):
    instance_information = client.describe_instance_information()
    instance_info = next((item for item in instance_information['InstanceInformationList'] if item.get(
        'Name') == managed_instance_name), None)
    return instance_info


def register_instance(activation):
    subprocess.check_call(['sudo', 'amazon-ssm-agent', '-register', '-id', activation['ActivationId'],
                           '-code', activation['ActivationCode'], '-region', 'eu-west-1'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def start_agent_process():
    subprocess.Popen(['sudo', 'amazon-ssm-agent'],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def kill_agent_process():
    for process in psutil.process_iter():
        try:
            if process.name() == 'amazon-ssm-agent':
                process.kill()
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass


def create_activation(managed_instance_name):
    return client.create_activation(
        DefaultInstanceName=managed_instance_name, IamRole='SSMServiceRole')


def clear_agent_configuration():
    subprocess.check_call(['sudo', 'amazon-ssm-agent', '-register', '-clear'],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def wait_for_managed_instance_online(managed_instance_name, retry_wait_time, retry_count):
    for _ in range(retry_count):
        managed_instance_id = describe_container_managed_instance(managed_instance_name)[
            'InstanceId']
        if client.get_connection_status(Target=managed_instance_id)['Status'] == 'connected':
            return True
        else:
            time.sleep(retry_wait_time)
    return False


@app.errorhandler(HTTPException)
def handle_exception(e):
    original_exception = getattr(e, 'original_exception')
    response = {
        'error_type': type(original_exception).__name__,
        'info': str(original_exception)
    }
    return response, 500


@app.route('/start-ssm-agent', methods=['PUT'])
def start_ssm_agent():
    container_metadata = requests.get(metadata_uri).json()
    managed_instance_name = f'{container_metadata["DockerId"]}-{container_metadata["DockerName"]}'
    managed_instance_info = describe_container_managed_instance(
        managed_instance_name)
    agent_running = check_agent_status()

    if managed_instance_info and agent_running:
        return {
            'instance_id': managed_instance_info['InstanceId']
        }
    elif not managed_instance_info and not agent_running:
        activation = create_activation(managed_instance_name)
        register_instance(activation)
    elif not managed_instance_info and agent_running:
        kill_agent_process()
        clear_agent_configuration()
        activation = create_activation(managed_instance_name)
        register_instance(activation)

    start_agent_process()

    if wait_for_managed_instance_online(managed_instance_name, 5, 5):
        return {
            'instance_id': describe_container_managed_instance(managed_instance_name)['InstanceId']
        }
    else:
        return {
            'error_type': 'Managed instance did not manage to come online',
            'info': describe_container_managed_instance(managed_instance_name)}, 500


app.run(host='0.0.0.0', port=5100)

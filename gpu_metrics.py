from fastapi import FastAPI
from fastapi.responses import JSONResponse
import pynvml
import time

app = FastAPI()

class GPUUsageManager:
    def __init__(self):
        # Initialize NVIDIA Management Library once
        pynvml.nvmlInit()

    def get_average_gpu_utilization(self, samples=5, delay=0.2):
        """
        Return average GPU utilization (%) across all GPUs.
        """
        device_count = pynvml.nvmlDeviceGetCount()
        gpu_samples = []

        for _ in range(samples):
            total_util = 0
            for i in range(device_count):
                handle = pynvml.nvmlDeviceGetHandleByIndex(i)
                util = pynvml.nvmlDeviceGetUtilizationRates(handle)
                total_util += util.gpu
            # Take average across GPUs for this sample
            avg_util_per_sample = total_util / max(device_count, 1)
            gpu_samples.append(avg_util_per_sample)
            time.sleep(delay)

        # Average over all collected samples
        return round(sum(gpu_samples) / len(gpu_samples), 2)

gpu_usage_manager = GPUUsageManager()

@app.get("/metrics")
async def metrics():
    gpu_util = gpu_usage_manager.get_average_gpu_utilization()
    # Format for KEDA: {"gpu_usage": {"ollama": <value>}}
    content = {"gpu_usage": {"ollama": gpu_util}}
    return JSONResponse(status_code=200, content=content)

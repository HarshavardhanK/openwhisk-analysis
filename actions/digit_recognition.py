import torch
import torchvision.transforms as transforms
from PIL import Image
import requests
from io import BytesIO

def get_image_from_url(url):
    """Download image from URL and convert to PIL Image"""
    response = requests.get(url)
    if response.status_code != 200:
        raise ValueError(f"Failed to download image: HTTP {response.status_code}")
    return Image.open(BytesIO(response.content)).convert('L')

def load_model():
    """Load pretrained MNIST model"""
    model = torch.hub.load('pytorch/vision:v0.10.0', 'mnist', pretrained=True)
    model.eval()
    return model

def preprocess_image(image):
    """Preprocess image for model input"""
    transform = transforms.Compose([
        transforms.Resize((28, 28)),
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    return transform(image).unsqueeze(0)

def predict_digit(model, input_tensor):
    """Run prediction and return digit and confidence"""
    with torch.no_grad():
        output = model(input_tensor)
        _, predicted_idx = torch.max(output, 1)
        
    digit = int(predicted_idx.item())
    confidence = float(torch.softmax(output, dim=1)[0][predicted_idx].item())
    return digit, confidence

def main(args):
    try:
        # Check if image_url is provided
        if "image_url" not in args:
            return {
                "error": "No image URL provided",
                "usage": "Invoke with {\"image_url\": \"https://example.com/digit.jpg\"}"
            }
        
        # Process image and make prediction
        image = get_image_from_url(args["image_url"])
        model = load_model()
        input_tensor = preprocess_image(image)
        digit, confidence = predict_digit(model, input_tensor)
        
        # Format response for OpenWhisk
        return {
            "digit": digit,
            "confidence": confidence,
            "message": f"Recognized digit: {digit} (confidence: {confidence:.4f})"
        }
    except Exception as e:
        return {"error": str(e)}
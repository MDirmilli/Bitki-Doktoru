# 🌿 Plant Doctor | Bitki Doktoru  
**AI-Powered Plant Disease Detection Application**

---

## 🇬🇧 English

### 📖 Project Overview

**Plant Doctor** is an AI-powered application that detects plant diseases by analyzing leaf images.  
The system uses a deep learning–based image classification model to provide **disease predictions along with confidence scores**.

This project was developed as part of an **Undergraduate Graduation Thesis**.

Early detection of plant diseases is critical for reducing crop losses and improving agricultural productivity.  
Plant Doctor allows users to analyze leaf images and automatically determine whether a plant is healthy or affected by a disease.

---

### ✨ Features

- Plant disease detection from leaf images  
- Deep learning–based image classification  
- Confidence score for each prediction  
- Pre-trained CNN model using transfer learning  
- Fast and reliable inference  
- Clean and user-friendly interface  

---

### 🧠 AI & Model Details

- **Model:** ResNet50 (Transfer Learning)
- **Framework:** TensorFlow / Keras
- **Input:** Leaf image
- **Output:** Disease class + confidence score
- **Loss Function:** Categorical Crossentropy
- **Optimizer:** Adam
- **Techniques Used:**
  - Data Augmentation
  - Fine-Tuning
  - Early Stopping
  - Model Checkpoint

---

### 🛠 Tech Stack

**AI / Machine Learning**
- Python  
- TensorFlow / Keras  
- NumPy  
- OpenCV  

**Application**
- Swift  
- SwiftUI  
- Xcode  
- MVVM Architecture  

---

### 📂 Dataset

- Plant Disease Dataset (Kaggle)  
- Labeled leaf images of various plant species and diseases  

---

### 🚀 How It Works

1. The user provides a leaf image  
2. The image is preprocessed and normalized  
3. The trained CNN model performs inference  
4. The system outputs the predicted disease class and confidence score  

**Sample Output**
```text
Prediction: Tomato___healthy
Confidence: 70%

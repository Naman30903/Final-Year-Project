# 🎯 Kaggle Notebook Quick Start Guide

## Problem Fixed! ✅

The error you saw was because the dataset path was incorrect. The notebook now **auto-detects** the correct dataset path.

## How to Run on Kaggle

### Step 1: Upload the Notebook
1. Go to Kaggle.com
2. Click **"New Notebook"** or **"Create"** → **"New Notebook"**
3. Click **"File"** → **"Import Notebook"**
4. Upload `kaggle_fake_news_detection.ipynb`

### Step 2: Add the Dataset
1. In the right panel, click **"+ Add Data"**
2. Search for: **"ISOT Fake News"** or **"fake and real news dataset"**
3. Click the dataset and add it
4. The dataset should appear under "Input" in the right panel

Popular datasets that work:
- `isot-fake-news-dataset` by therohk
- `fake-and-real-news-dataset` by clmentbisaillon

### Step 3: Enable GPU (Recommended)
1. Click the **Settings** icon (⚙️) in the top right
2. Under **"Accelerator"**, select **"GPU"** (or "T4 GPU")
3. Click **"Save"**

### Step 4: Run All Cells
1. Click **"Run All"** button at the top
2. OR press **Shift + Enter** to run cells one by one

## What the Notebook Does

### 📊 Data Processing
- Loads Fake.csv and True.csv
- Cleans text (removes URLs, special characters)
- Tokenizes and pads sequences
- Splits into training/validation sets

### 🤖 Model Training
- **K-Fold Cross Validation** (5 folds)
- **Architecture**: Embedding → Conv1D → BiLSTM → Attention → Dense
- **Regularization**: L2 + Dropout
- **Callbacks**: Early Stopping, Model Checkpointing, Learning Rate Reduction

### 📈 Evaluation
- Per-fold performance metrics
- Overall classification report
- Confusion matrix
- Training/validation plots

### 🔮 Advanced Features
- Counterfactual generation
- Word importance analysis
- Sample article testing

### 💾 Output Files
All saved to `/kaggle/working/`:
- `models/model_fold1.h5` through `model_fold5.h5` - Trained models
- `tokenizer.pkl` - Fitted tokenizer
- `results.json` - Performance metrics
- `counterfactual_examples.json` - Generated counterfactuals

## Expected Runtime

With GPU enabled:
- Data loading: ~1 minute
- Training (5 folds, ~10-20 epochs each): ~30-60 minutes total
- Evaluation and visualization: ~5 minutes

**Total: ~45-70 minutes**

Without GPU: 3-5x longer

## Downloading Results

### Method 1: Individual Files
1. Check the **"Output"** section in the right panel
2. Click the download icon next to each file

### Method 2: Create Dataset
1. After notebook finishes running
2. In the right panel, click **"Save Version"**
3. Then click **"Save & Create Dataset"**
4. This creates a new Kaggle dataset with all output files
5. You can reuse this dataset in other notebooks

## Troubleshooting

### ❌ "Dataset files not found"
**Solution:** The auto-detection cell will show you:
- Available datasets in your notebook
- Expected file paths
- Make sure you've added a dataset that contains `Fake.csv` and `True.csv`

### ❌ "Out of memory"
**Solutions:**
- Make sure GPU is enabled (Settings → Accelerator → GPU)
- Reduce `BATCH_SIZE` from 64 to 32 (in cell 7)
- Reduce `MAX_LENGTH` from 300 to 200 (in cell 5)
- Reduce `VOCAB_SIZE` from 10000 to 5000 (in cell 5)

### ❌ Training takes too long
**Solutions:**
- Reduce `N_FOLDS` from 5 to 3 (in cell 7)
- Reduce `EPOCHS` from 20 to 10 (in cell 7)
- Early stopping will stop training automatically if no improvement

### ❌ "Session expired" or "Notebook timeout"
**Solution:**
- Kaggle free tier has session limits (~9 hours/week GPU, ~30 hours/week CPU)
- The notebook saves checkpoints, so you can resume
- Or reduce folds/epochs to finish faster

## Customization

### Change Model Architecture
Edit the `build_model()` function in cell 6:
- Adjust layer sizes
- Add/remove layers
- Change regularization strength

### Adjust Hyperparameters
In cell 5 and cell 7:
```python
VOCAB_SIZE = 10000    # Vocabulary size
MAX_LENGTH = 300      # Max sequence length
EMBEDDING_DIM = 128   # Embedding dimensions
N_FOLDS = 5           # Number of folds
EPOCHS = 20           # Max epochs per fold
BATCH_SIZE = 64       # Batch size
```

### Use Different Dataset
The notebook auto-detects paths, but you can manually set:
```python
INPUT_PATH = '/kaggle/input/your-dataset-name'
```

## Using the Trained Model

### Load Model for Inference
```python
from tensorflow.keras.models import load_model
import pickle

# Load model
model = load_model('/kaggle/working/models/model_fold1.h5')

# Load tokenizer
with open('/kaggle/working/tokenizer.pkl', 'rb') as f:
    tokenizer = pickle.load(f)

# Predict
def predict(text):
    cleaned = clean_text(text)
    seq = tokenizer.texts_to_sequences([cleaned])
    padded = pad_sequences(seq, maxlen=300, padding='post')
    prob = model.predict(padded)[0][0]
    return 'FAKE' if prob > 0.5 else 'REAL'
```

## Integration with Go Backend

After downloading the model files:
1. Create a Python FastAPI service (see `ml_service_api.py` in backend)
2. Load the model and tokenizer
3. Expose `/predict` endpoint
4. Deploy to Hugging Face Spaces or Render
5. Connect your Go backend to this service

## Performance Expectations

Typical results with this notebook:
- **Accuracy**: 98-99%
- **Precision**: 98-99%
- **Recall**: 98-99%
- **F1-Score**: 98-99%

The ISOT dataset is relatively clean, so high accuracy is expected.

## Features Implemented ✅

- [x] K-Fold Cross Validation
- [x] L2 Regularization
- [x] Dropout Regularization
- [x] Early Stopping
- [x] Model Checkpointing
- [x] Learning Rate Scheduling
- [x] Comprehensive Metrics
- [x] Visualization
- [x] Counterfactual Generation
- [x] Auto-path Detection
- [x] Artifact Saving

## Need Help?

1. Check the error messages in the notebook output
2. The auto-detection cell shows detailed diagnostics
3. Refer to Kaggle documentation: https://www.kaggle.com/docs
4. Check TensorFlow/Keras docs for model issues

## Next Steps After Training

1. **Evaluate Results**: Check metrics in cell 8
2. **Visualize Performance**: Review plots in cell 9
3. **Test Samples**: See predictions in cell 10
4. **Analyze Counterfactuals**: Review cell 11
5. **Download Models**: From Output panel
6. **Deploy**: Create API service
7. **Integrate**: Connect to your Go backend

---

**Ready to run!** 🚀

Just follow Steps 1-4 above and you'll have a trained fake news detection model in about an hour!

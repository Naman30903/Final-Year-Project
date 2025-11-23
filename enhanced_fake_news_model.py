# -*- coding: utf-8 -*-
"""
Enhanced Fake News Detection Model
with K-Fold Cross Validation, Regularization, Early Stopping, and Counterfactual Generator
"""

import pandas as pd
import numpy as np
import re
import os
from sklearn.model_selection import KFold, train_test_split
from sklearn.metrics import classification_report, confusion_matrix
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import (
    Input, Embedding, Conv1D, MaxPooling1D,
    Bidirectional, LSTM, Dense, Dropout, Attention
)
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
from tensorflow.keras.regularizers import l2
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
import matplotlib.pyplot as plt
import pickle

# ============================================================================
# STEP 1: DATA LOADING AND PREPROCESSING
# ============================================================================

print("=" * 70)
print("STEP 1: Loading and Preparing ISOT Dataset")
print("=" * 70)

# --- 1.1 Define File Paths ---
base_path = '/content/'
fake_path = os.path.join(base_path, 'Fake.csv')
real_path = os.path.join(base_path, 'True.csv')

# --- 1.2 Load Data ---
df_fake = pd.read_csv(fake_path, on_bad_lines='skip', engine='python')
df_real = pd.read_csv(real_path, on_bad_lines='skip', engine='python')

print(f"✓ Loaded {len(df_fake)} fake articles")
print(f"✓ Loaded {len(df_real)} real articles")

# --- 1.3 Label and Combine ---
df_fake['label'] = 1  # 1 for 'fake'
df_real['label'] = 0  # 0 for 'real'

df_combined = pd.concat([df_fake, df_real], ignore_index=True)
df_combined['full_text'] = df_combined['title'] + " " + df_combined['text']
df_combined = df_combined.sample(frac=1, random_state=42).reset_index(drop=True)
df_combined = df_combined.dropna(subset=['full_text'])

print(f"✓ Total articles: {len(df_combined)}")

# --- 1.4 Text Cleaning Function ---
def clean_text(text):
    """Clean and normalize text data"""
    text = str(text).lower()
    # Remove source tags and location markers
    text = re.sub(r'\(reuters\)|(washington|london|moscow|etc) -', '', text)
    # Remove special characters
    text = re.sub(r'[^a-zA-Z\s]', '', text)
    # Remove extra whitespace
    text = ' '.join(text.split())
    return text

print("\n✓ Cleaning text data...")
df_combined['cleaned_text'] = df_combined['full_text'].apply(clean_text)

# --- 1.5 Tokenization Parameters ---
VOCAB_SIZE = 10000
MAX_LENGTH = 300
EMBEDDING_DIM = 64

labels = df_combined['label'].values
articles = df_combined['cleaned_text'].values

# Initialize and fit tokenizer
tokenizer = Tokenizer(num_words=VOCAB_SIZE, oov_token='<OOV>')
tokenizer.fit_on_texts(articles)

# Convert text to sequences
sequences = tokenizer.texts_to_sequences(articles)
padded_sequences = pad_sequences(sequences, maxlen=MAX_LENGTH,
                                 padding='post', truncating='post')

print(f"✓ Padded sequences shape: {padded_sequences.shape}")

# Save tokenizer for later use
with open('tokenizer.pkl', 'wb') as f:
    pickle.dump(tokenizer, f)
print("✓ Tokenizer saved to 'tokenizer.pkl'")


# ============================================================================
# STEP 2: MODEL ARCHITECTURE WITH REGULARIZATION
# ============================================================================

print("\n" + "=" * 70)
print("STEP 2: Building Model Architecture with Regularization")
print("=" * 70)

def create_model(vocab_size=VOCAB_SIZE, max_length=MAX_LENGTH, 
                 embedding_dim=EMBEDDING_DIM, l2_reg=0.01):
    """
    Create the fake news detection model with regularization
    
    Args:
        vocab_size: Size of vocabulary
        max_length: Maximum sequence length
        embedding_dim: Dimension of embedding layer
        l2_reg: L2 regularization factor
    
    Returns:
        Compiled Keras model
    """
    input_layer = Input(shape=(max_length,), name="input_layer")
    
    # Embedding layer with regularization
    embedding_layer = Embedding(
        input_dim=vocab_size,
        output_dim=embedding_dim,
        embeddings_regularizer=l2(l2_reg),
        name="embedding_layer"
    )(input_layer)
    
    # Convolutional layer with regularization
    conv_layer = Conv1D(
        filters=32, 
        kernel_size=5, 
        activation='relu',
        kernel_regularizer=l2(l2_reg),
        name="convolutional_layer"
    )(embedding_layer)
    
    pool_layer = MaxPooling1D(pool_size=2, name="pooling_layer")(conv_layer)
    
    # Bidirectional LSTM with regularization
    bilstm_layer = Bidirectional(
        LSTM(32, return_sequences=True, 
             kernel_regularizer=l2(l2_reg),
             recurrent_regularizer=l2(l2_reg)),
        name="bilstm_layer"
    )(pool_layer)
    
    # Attention mechanism
    attention_result = Attention(name="attention_layer")([bilstm_layer, bilstm_layer])
    
    # Final LSTM layer with regularization
    final_lstm = Bidirectional(
        LSTM(16, return_sequences=False,
             kernel_regularizer=l2(l2_reg),
             recurrent_regularizer=l2(l2_reg)),
        name="final_lstm_layer"
    )(attention_result)
    
    # Dropout for additional regularization
    dropout_layer = Dropout(0.5, name="dropout_layer")(final_lstm)
    
    # Dense layer with regularization
    dense_layer = Dense(
        32, 
        activation='relu',
        kernel_regularizer=l2(l2_reg),
        name="dense_layer"
    )(dropout_layer)
    
    # Output layer
    output_layer = Dense(1, activation='sigmoid', name="output_layer")(dense_layer)
    
    model = Model(inputs=input_layer, outputs=output_layer)
    
    # Compile model
    model.compile(
        loss='binary_crossentropy',
        optimizer='adam',
        metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
    )
    
    return model

print("✓ Model architecture defined with L2 regularization")


# ============================================================================
# STEP 3: K-FOLD CROSS VALIDATION
# ============================================================================

print("\n" + "=" * 70)
print("STEP 3: K-Fold Cross Validation Training")
print("=" * 70)

N_FOLDS = 5
EPOCHS = 10
BATCH_SIZE = 64

# Prepare K-Fold
kfold = KFold(n_splits=N_FOLDS, shuffle=True, random_state=42)

# Store results
fold_accuracies = []
fold_losses = []
fold_histories = []

print(f"\nStarting {N_FOLDS}-Fold Cross Validation...")

for fold, (train_idx, val_idx) in enumerate(kfold.split(padded_sequences), 1):
    print(f"\n{'=' * 70}")
    print(f"Training Fold {fold}/{N_FOLDS}")
    print(f"{'=' * 70}")
    
    # Split data
    X_train_fold = padded_sequences[train_idx]
    y_train_fold = labels[train_idx]
    X_val_fold = padded_sequences[val_idx]
    y_val_fold = labels[val_idx]
    
    print(f"Train samples: {len(X_train_fold)}, Validation samples: {len(X_val_fold)}")
    
    # Create fresh model for this fold
    model = create_model(l2_reg=0.01)
    
    # Enhanced callbacks
    callbacks = [
        # Early stopping with patience
        EarlyStopping(
            monitor='val_loss',
            patience=3,
            restore_best_weights=True,
            verbose=1
        ),
        # Reduce learning rate on plateau
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=2,
            min_lr=1e-7,
            verbose=1
        ),
        # Save best model
        ModelCheckpoint(
            f'best_model_fold_{fold}.h5',
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        )
    ]
    
    # Train model
    history = model.fit(
        X_train_fold, y_train_fold,
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        validation_data=(X_val_fold, y_val_fold),
        callbacks=callbacks,
        verbose=1
    )
    
    # Evaluate fold
    loss, accuracy, precision, recall = model.evaluate(X_val_fold, y_val_fold, verbose=0)
    
    fold_accuracies.append(accuracy)
    fold_losses.append(loss)
    fold_histories.append(history.history)
    
    print(f"\n✓ Fold {fold} Results:")
    print(f"  - Accuracy: {accuracy * 100:.2f}%")
    print(f"  - Loss: {loss:.4f}")
    print(f"  - Precision: {precision:.4f}")
    print(f"  - Recall: {recall:.4f}")

# Print overall results
print("\n" + "=" * 70)
print("K-FOLD CROSS VALIDATION RESULTS")
print("=" * 70)
print(f"Mean Accuracy: {np.mean(fold_accuracies) * 100:.2f}% (+/- {np.std(fold_accuracies) * 100:.2f}%)")
print(f"Mean Loss: {np.mean(fold_losses):.4f} (+/- {np.std(fold_losses):.4f})")
print(f"\nFold-wise Accuracies:")
for i, acc in enumerate(fold_accuracies, 1):
    print(f"  Fold {i}: {acc * 100:.2f}%")


# ============================================================================
# STEP 4: TRAIN FINAL MODEL ON FULL DATA
# ============================================================================

print("\n" + "=" * 70)
print("STEP 4: Training Final Model on Full Dataset")
print("=" * 70)

# Split data for final model
X_train, X_test, y_train, y_test = train_test_split(
    padded_sequences, labels,
    test_size=0.2,
    random_state=42
)

print(f"Train samples: {len(X_train)}, Test samples: {len(X_test)}")

# Create final model
final_model = create_model(l2_reg=0.01)
final_model.summary()

# Enhanced callbacks for final model
final_callbacks = [
    EarlyStopping(
        monitor='val_loss',
        patience=3,
        restore_best_weights=True,
        verbose=1
    ),
    ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=2,
        min_lr=1e-7,
        verbose=1
    ),
    ModelCheckpoint(
        'final_best_model.h5',
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    )
]

# Train final model
print("\n✓ Training final model...")
final_history = final_model.fit(
    X_train, y_train,
    epochs=EPOCHS,
    batch_size=BATCH_SIZE,
    validation_data=(X_test, y_test),
    callbacks=final_callbacks,
    verbose=1
)

# Evaluate final model
print("\n" + "=" * 70)
print("FINAL MODEL EVALUATION")
print("=" * 70)

loss, accuracy, precision, recall = final_model.evaluate(X_test, y_test)
print(f"✓ Test Accuracy: {accuracy * 100:.2f}%")
print(f"✓ Test Loss: {loss:.4f}")
print(f"✓ Precision: {precision:.4f}")
print(f"✓ Recall: {recall:.4f}")
print(f"✓ F1-Score: {2 * (precision * recall) / (precision + recall):.4f}")

# Generate predictions
y_pred_probs = final_model.predict(X_test)
y_pred_classes = (y_pred_probs > 0.5).astype(int)

# Classification report
print("\n" + "=" * 70)
print("CLASSIFICATION REPORT")
print("=" * 70)
report = classification_report(y_test, y_pred_classes, 
                              target_names=['Real (0)', 'Fake (1)'])
print(report)

# Confusion matrix
print("\n" + "=" * 70)
print("CONFUSION MATRIX")
print("=" * 70)
cm = confusion_matrix(y_test, y_pred_classes)
print(cm)
print(f"\nTrue Negatives: {cm[0][0]}")
print(f"False Positives: {cm[0][1]}")
print(f"False Negatives: {cm[1][0]}")
print(f"True Positives: {cm[1][1]}")

# Save final model
final_model.save('fake_news_detector_final.h5')
print("\n✓ Final model saved as 'fake_news_detector_final.h5'")


# ============================================================================
# STEP 5: VISUALIZATION
# ============================================================================

print("\n" + "=" * 70)
print("STEP 5: Generating Visualizations")
print("=" * 70)

# Plot training history
fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# Accuracy plot
axes[0, 0].plot(final_history.history['accuracy'], label='Train Accuracy')
axes[0, 0].plot(final_history.history['val_accuracy'], label='Val Accuracy')
axes[0, 0].set_title('Model Accuracy')
axes[0, 0].set_xlabel('Epoch')
axes[0, 0].set_ylabel('Accuracy')
axes[0, 0].legend()
axes[0, 0].grid(True)

# Loss plot
axes[0, 1].plot(final_history.history['loss'], label='Train Loss')
axes[0, 1].plot(final_history.history['val_loss'], label='Val Loss')
axes[0, 1].set_title('Model Loss')
axes[0, 1].set_xlabel('Epoch')
axes[0, 1].set_ylabel('Loss')
axes[0, 1].legend()
axes[0, 1].grid(True)

# Precision plot
axes[1, 0].plot(final_history.history['precision'], label='Train Precision')
axes[1, 0].plot(final_history.history['val_precision'], label='Val Precision')
axes[1, 0].set_title('Model Precision')
axes[1, 0].set_xlabel('Epoch')
axes[1, 0].set_ylabel('Precision')
axes[1, 0].legend()
axes[1, 0].grid(True)

# Recall plot
axes[1, 1].plot(final_history.history['recall'], label='Train Recall')
axes[1, 1].plot(final_history.history['val_recall'], label='Val Recall')
axes[1, 1].set_title('Model Recall')
axes[1, 1].set_xlabel('Epoch')
axes[1, 1].set_ylabel('Recall')
axes[1, 1].legend()
axes[1, 1].grid(True)

plt.tight_layout()
plt.savefig('training_metrics.png', dpi=300)
print("✓ Training metrics saved as 'training_metrics.png'")
plt.show()

# Plot K-Fold results
plt.figure(figsize=(10, 6))
plt.bar(range(1, N_FOLDS + 1), [acc * 100 for acc in fold_accuracies])
plt.axhline(y=np.mean(fold_accuracies) * 100, color='r', 
            linestyle='--', label=f'Mean: {np.mean(fold_accuracies) * 100:.2f}%')
plt.xlabel('Fold')
plt.ylabel('Accuracy (%)')
plt.title('K-Fold Cross Validation Results')
plt.legend()
plt.grid(True, alpha=0.3)
plt.savefig('kfold_results.png', dpi=300)
print("✓ K-Fold results saved as 'kfold_results.png'")
plt.show()


# ============================================================================
# STEP 6: COUNTERFACTUAL GENERATOR
# ============================================================================

print("\n" + "=" * 70)
print("STEP 6: Counterfactual Generator Implementation")
print("=" * 70)

class CounterfactualGenerator:
    """
    Generate counterfactual explanations for fake news predictions
    """
    
    def __init__(self, model, tokenizer, max_length=MAX_LENGTH):
        self.model = model
        self.tokenizer = tokenizer
        self.max_length = max_length
        
        # Words commonly associated with fake news
        self.fake_indicators = [
            'shocking', 'unbelievable', 'bombshell', 'exclusive', 'breaking',
            'revealed', 'exposed', 'conspiracy', 'hidden', 'secret',
            'truth', 'they dont want you to know', 'mainstream media',
            'click here', 'share this', 'wow', 'incredible', 'amazing'
        ]
        
        # Neutral replacements
        self.neutral_replacements = {
            'shocking': 'notable',
            'unbelievable': 'significant',
            'bombshell': 'report',
            'exclusive': 'news',
            'breaking': 'recent',
            'revealed': 'reported',
            'exposed': 'disclosed',
            'conspiracy': 'theory',
            'hidden': 'undisclosed',
            'secret': 'private',
            'incredible': 'noteworthy',
            'amazing': 'interesting'
        }
    
    def clean_text(self, text):
        """Clean and normalize text"""
        text = str(text).lower()
        text = re.sub(r'\(reuters\)|(washington|london|moscow|etc) -', '', text)
        text = re.sub(r'[^a-zA-Z\s]', '', text)
        text = ' '.join(text.split())
        return text
    
    def predict(self, text):
        """Make prediction on text"""
        cleaned = self.clean_text(text)
        seq = self.tokenizer.texts_to_sequences([cleaned])
        padded = pad_sequences(seq, maxlen=self.max_length,
                              padding='post', truncating='post')
        prob = self.model.predict(padded, verbose=0)[0][0]
        return prob
    
    def generate_counterfactual(self, original_text, target_class='flip', 
                               max_iterations=50):
        """
        Generate a counterfactual by modifying the text
        
        Args:
            original_text: Original news article
            target_class: 'flip' to flip prediction, 'real' to make real, 
                         'fake' to make fake
            max_iterations: Maximum number of modification attempts
        
        Returns:
            dict with original text, modified text, original prediction,
            new prediction, and modifications made
        """
        original_pred = self.predict(original_text)
        original_class = 'FAKE' if original_pred > 0.5 else 'REAL'
        
        # Determine target
        if target_class == 'flip':
            target = 0.0 if original_pred > 0.5 else 1.0
        elif target_class == 'real':
            target = 0.0
        elif target_class == 'fake':
            target = 1.0
        else:
            raise ValueError("target_class must be 'flip', 'real', or 'fake'")
        
        modified_text = original_text
        modifications = []
        
        # Strategy 1: Remove/Replace fake indicators
        if target == 0.0:  # Make it look more real
            words = modified_text.split()
            for i, word in enumerate(words):
                word_clean = re.sub(r'[^a-zA-Z]', '', word.lower())
                if word_clean in self.fake_indicators:
                    replacement = self.neutral_replacements.get(word_clean, '')
                    if replacement:
                        words[i] = replacement
                        modifications.append(f"Replaced '{word}' with '{replacement}'")
            modified_text = ' '.join(words)
        
        # Strategy 2: Add fake indicators
        elif target == 1.0:  # Make it look more fake
            fake_phrases = [
                'BREAKING: ',
                'SHOCKING: ',
                'You won\'t believe this! ',
                'EXCLUSIVE: ',
                'Share before deleted! '
            ]
            modified_text = np.random.choice(fake_phrases) + modified_text
            modifications.append(f"Added sensational prefix")
        
        # Check new prediction
        new_pred = self.predict(modified_text)
        new_class = 'FAKE' if new_pred > 0.5 else 'REAL'
        
        return {
            'original_text': original_text,
            'modified_text': modified_text,
            'original_prediction': original_pred,
            'original_class': original_class,
            'new_prediction': new_pred,
            'new_class': new_class,
            'modifications': modifications,
            'success': (new_pred > 0.5) == (target > 0.5)
        }
    
    def explain_prediction(self, text, num_samples=5):
        """
        Generate multiple counterfactuals to explain prediction
        """
        print(f"\n{'=' * 70}")
        print("COUNTERFACTUAL EXPLANATION")
        print(f"{'=' * 70}")
        
        original_pred = self.predict(text)
        original_class = 'FAKE' if original_pred > 0.5 else 'REAL'
        
        print(f"\n📰 Original Text (first 200 chars):")
        print(f"{text[:200]}...")
        print(f"\n🎯 Original Prediction: {original_class}")
        print(f"   Confidence: {original_pred * 100:.2f}%")
        
        print(f"\n{'=' * 70}")
        print("Generating Counterfactuals...")
        print(f"{'=' * 70}")
        
        counterfactual = self.generate_counterfactual(text, target_class='flip')
        
        print(f"\n📝 Modified Text (first 200 chars):")
        print(f"{counterfactual['modified_text'][:200]}...")
        print(f"\n🎯 New Prediction: {counterfactual['new_class']}")
        print(f"   Confidence: {counterfactual['new_prediction'] * 100:.2f}%")
        print(f"\n✏️  Modifications Made:")
        for mod in counterfactual['modifications']:
            print(f"   - {mod}")
        print(f"\n✅ Counterfactual Generation: {'SUCCESS' if counterfactual['success'] else 'PARTIAL'}")
        
        return counterfactual

# Initialize counterfactual generator
cf_generator = CounterfactualGenerator(final_model, tokenizer, MAX_LENGTH)
print("✓ Counterfactual Generator initialized")


# ============================================================================
# STEP 7: TESTING WITH EXAMPLES
# ============================================================================

print("\n" + "=" * 70)
print("STEP 7: Testing Predictions and Counterfactuals")
print("=" * 70)

# Test Article 1: Fake News Example
fake_article = """
(EXCLUSIVE) Top Scientist CONFIRMS Election Was Stolen!
In a shocking turn of events, a scientist who wished to remain anonymous
has come forward with PROOF of a massive conspiracy. He claims
"The votes were switched, millions of them. I saw it with my own eyes."
This is the bombshell report the media doesn't want you to see!
Share this before they take it down!
"""

print("\n" + "=" * 70)
print("TEST 1: Analyzing Fake News Article")
print("=" * 70)

pred1 = cf_generator.predict(fake_article)
print(f"\n📰 Article Type: FAKE NEWS EXAMPLE")
print(f"🎯 Prediction: {'FAKE' if pred1 > 0.5 else 'REAL'}")
print(f"   Confidence: {pred1 * 100:.2f}%")

# Generate counterfactual for fake article
cf1 = cf_generator.explain_prediction(fake_article)

# Test Article 2: Real News Example
real_article = """
The nation's central bank signaled on Wednesday that it may
continue with its current monetary policy, citing recent
data showing moderate economic growth.

In a press release, officials noted that inflation remains
below their 2% target. They also stated that the labor market
has shown signs of continued strengthening. The committee
voted unanimously to maintain the federal funds rate at its
current level.
"""

print("\n" + "=" * 70)
print("TEST 2: Analyzing Real News Article")
print("=" * 70)

pred2 = cf_generator.predict(real_article)
print(f"\n📰 Article Type: REAL NEWS EXAMPLE")
print(f"🎯 Prediction: {'FAKE' if pred2 > 0.5 else 'REAL'}")
print(f"   Confidence: {(1 - pred2) * 100:.2f}%")

# Generate counterfactual for real article
cf2 = cf_generator.explain_prediction(real_article)


# ============================================================================
# STEP 8: SAVE ALL ARTIFACTS
# ============================================================================

print("\n" + "=" * 70)
print("STEP 8: Saving All Model Artifacts")
print("=" * 70)

# Save configuration
config = {
    'vocab_size': VOCAB_SIZE,
    'max_length': MAX_LENGTH,
    'embedding_dim': EMBEDDING_DIM,
    'n_folds': N_FOLDS,
    'epochs': EPOCHS,
    'batch_size': BATCH_SIZE,
    'l2_regularization': 0.01,
    'mean_cv_accuracy': np.mean(fold_accuracies),
    'std_cv_accuracy': np.std(fold_accuracies),
    'final_test_accuracy': accuracy,
    'final_test_precision': precision,
    'final_test_recall': recall
}

with open('model_config.pkl', 'wb') as f:
    pickle.dump(config, f)

print("✓ Model configuration saved to 'model_config.pkl'")
print("✓ Tokenizer saved to 'tokenizer.pkl'")
print("✓ Final model saved to 'fake_news_detector_final.h5'")
print("✓ Best model checkpoints saved for each fold")

print("\n" + "=" * 70)
print("🎉 ALL STEPS COMPLETED SUCCESSFULLY!")
print("=" * 70)
print("\n📊 Final Summary:")
print(f"   - K-Fold CV Accuracy: {np.mean(fold_accuracies) * 100:.2f}% ± {np.std(fold_accuracies) * 100:.2f}%")
print(f"   - Test Accuracy: {accuracy * 100:.2f}%")
print(f"   - Test Precision: {precision:.4f}")
print(f"   - Test Recall: {recall:.4f}")
print(f"   - Model with regularization: ✓")
print(f"   - Early stopping: ✓")
print(f"   - Learning rate reduction: ✓")
print(f"   - Counterfactual generator: ✓")
print("\n🚀 Your enhanced fake news detection model is ready!")

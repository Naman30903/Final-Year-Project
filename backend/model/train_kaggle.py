"""
Fake News Detection — RoBERTa Fine-Tuning
==========================================
Run this on Kaggle (GPU T4 x2 or P100) as a notebook, or locally.

Cell markers (# %%) are recognised by Kaggle, VS Code, and Jupyter.

Quick start on Kaggle
─────────────────────
1. Create a new Kaggle notebook → upload this file.
2. Enable GPU accelerator in Settings.
3. Add the dataset:  "GonzagaFakeNewsDataset" (WELFake) or your own CSV.
4. Set HF_TOKEN in Kaggle Secrets (Add-ons → Secrets) for Hub push.
5. Run all cells.

Dataset expected schema
───────────────────────
A CSV with at minimum two columns:
  text   – full article text
  label  – 0 = FAKE, 1 = REAL
"""

# %% [markdown]
# ## 0 · Install / imports

# %%
# On Kaggle these are pre-installed; uncomment if running locally.
# !pip install -q transformers datasets accelerate scikit-learn pydantic

import os
import inspect
import warnings
warnings.filterwarnings("ignore")

import numpy as np
import pandas as pd
from datasets import Dataset, DatasetDict
from sklearn.metrics import (
    accuracy_score, classification_report, confusion_matrix
)
from sklearn.model_selection import train_test_split
from transformers import (
    AutoModelForSequenceClassification,
    AutoTokenizer,
    DataCollatorWithPadding,
    Trainer,
    TrainingArguments,
    EarlyStoppingCallback,
)
import torch

print(f"PyTorch  : {torch.__version__}")
print(f"CUDA     : {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU      : {torch.cuda.get_device_name(0)}")

# %% [markdown]
# ## 1 · Config — edit these before running

# %%
CFG = dict(
    # ── Data ──────────────────────────────────────────────────────────────
    # On Kaggle set this to the path shown after adding the dataset, e.g.:
    #   /kaggle/input/welfake-dataset/WELFake_Dataset.csv
    csv_path        = "/kaggle/input/datasets/saurabhshahane/fake-news-classification/WELFake_Dataset.csv",
    text_col        = "text",          # column name for article body
    label_col       = "label",         # 0=FAKE, 1=REAL
    test_size       = 0.10,            # 10 % held-out test set
    val_size        = 0.10,            # 10 % of training → validation
    max_samples     = None,            # set an int to subsample (fast debug)

    # ── Model ─────────────────────────────────────────────────────────────
    base_model      = "roberta-base",  # or "distilroberta-base" for speed
    max_length      = 384,

    # ── Training ──────────────────────────────────────────────────────────
    output_dir      = "/kaggle/working/",
    num_epochs      = 3,
    batch_size      = 16,              # per device; reduce to 8 if OOM
    lr              = 2e-5,
    fp16            = True,            # False on CPU / MPS

    # ── Hub push ──────────────────────────────────────────────────────────
    push_to_hub     = True,
    hub_model_id    = "Naman30903/roberta-fakenews",  # ← change this
    # Read token from Kaggle secret OR env var:
    hf_token        = os.getenv("HF_TOKEN", ""),
)

# %% [markdown]
# ## 2 · Load & clean data

# %%
df = pd.read_csv(CFG["csv_path"])
print(f"Raw rows: {len(df):,}  |  columns: {list(df.columns)}")

# Keep only the two columns we need
df = df[[CFG["text_col"], CFG["label_col"]]].rename(
    columns={CFG["text_col"]: "text", CFG["label_col"]: "label"}
)

# Drop rows with missing text or unexpected labels
df = df.dropna(subset=["text", "label"])
df = df[df["label"].isin([0, 1])]
df["text"] = df["text"].astype(str).str.strip()
df = df[df["text"].str.len() > 20]
df["label"] = df["label"].astype(int)

if CFG["max_samples"]:
    df = df.sample(CFG["max_samples"], random_state=42)

print(f"Clean rows: {len(df):,}")
print(df["label"].value_counts().rename({0: "FAKE", 1: "REAL"}))

# %%  train / val / test split
train_val_df, test_df = train_test_split(
    df, test_size=CFG["test_size"], stratify=df["label"], random_state=42
)
train_df, val_df = train_test_split(
    train_val_df,
    test_size=CFG["val_size"] / (1 - CFG["test_size"]),
    stratify=train_val_df["label"],
    random_state=42,
)

print(f"Train: {len(train_df):,}  |  Val: {len(val_df):,}  |  Test: {len(test_df):,}")

dd = DatasetDict({
    "train": Dataset.from_pandas(train_df.reset_index(drop=True)),
    "validation": Dataset.from_pandas(val_df.reset_index(drop=True)),
    "test": Dataset.from_pandas(test_df.reset_index(drop=True)),
})

# %% [markdown]
# ## 3 · Tokenise

# %%
tokenizer = AutoTokenizer.from_pretrained(CFG["base_model"])

def tokenise(batch):
    return tokenizer(
        batch["text"],
        truncation=True,
        max_length=CFG["max_length"],
    )

tokenised = dd.map(tokenise, batched=True, remove_columns=["text"])
collator = DataCollatorWithPadding(tokenizer)
print(tokenised)

# %% [markdown]
# ## 4 · Model

# %%
id2label = {0: "FAKE", 1: "REAL"}
label2id = {"FAKE": 0, "REAL": 1}

model = AutoModelForSequenceClassification.from_pretrained(
    CFG["base_model"],
    num_labels=2,
    id2label=id2label,
    label2id=label2id,
)

# %% [markdown]
# ## 5 · Metrics

# %%
def compute_metrics(eval_pred):
    logits, labels = eval_pred
    preds = np.argmax(logits, axis=-1)
    return {
        "accuracy": accuracy_score(labels, preds),
        "f1_fake": classification_report(
            labels, preds, output_dict=True, zero_division=0
        )["0"]["f1-score"],
        "f1_real": classification_report(
            labels, preds, output_dict=True, zero_division=0
        )["1"]["f1-score"],
    }

# %% [markdown]
# ## 6 · Train

# %%
training_args = TrainingArguments(
    output_dir                  = CFG["output_dir"],
    num_train_epochs            = CFG["num_epochs"],
    per_device_train_batch_size = CFG["batch_size"],
    per_device_eval_batch_size  = CFG["batch_size"] * 2,
    learning_rate               = CFG["lr"],
    fp16                        = CFG["fp16"] and torch.cuda.is_available(),
    eval_strategy               = "epoch",
    save_strategy               = "epoch",
    load_best_model_at_end      = True,
    metric_for_best_model       = "accuracy",
    greater_is_better           = True,
    logging_steps               = 50,
    report_to                   = "none",
    push_to_hub                 = False,   # we push manually below
)

trainer_kwargs = dict(
    model           = model,
    args            = training_args,
    train_dataset   = tokenised["train"],
    eval_dataset    = tokenised["validation"],
    data_collator   = collator,
    compute_metrics = compute_metrics,
    callbacks       = [EarlyStoppingCallback(early_stopping_patience=2)],
)

# transformers changed Trainer API: `tokenizer` -> `processing_class`.
trainer_init_params = inspect.signature(Trainer.__init__).parameters
if "tokenizer" in trainer_init_params:
    trainer_kwargs["tokenizer"] = tokenizer
elif "processing_class" in trainer_init_params:
    trainer_kwargs["processing_class"] = tokenizer

trainer = Trainer(**trainer_kwargs)

trainer.train()

# %% [markdown]
# ## 7 · Evaluate on held-out test set

# %%
test_results = trainer.predict(tokenised["test"])
preds = np.argmax(test_results.predictions, axis=-1)
labels = test_results.label_ids

print("\n=== Test-set results ===")
print(classification_report(labels, preds, target_names=["FAKE", "REAL"]))
print("Confusion matrix:\n", confusion_matrix(labels, preds))

# %% [markdown]
# ## 8 · Save locally (always) + push to Hub (if configured)

# %%
# Always save to /kaggle/working so you can download as a Kaggle output
local_save = CFG["output_dir"] + "/final"
trainer.save_model(local_save)
tokenizer.save_pretrained(local_save)
print(f"Model saved to: {local_save}")

# %%
if CFG["push_to_hub"] and CFG["hf_token"] and "YOUR_HF_USERNAME" not in CFG["hub_model_id"]:
    print(f"Pushing to Hub: {CFG['hub_model_id']} ...")
    from huggingface_hub import HfApi
    api = HfApi()

    # Login
    from huggingface_hub import login
    login(token=CFG["hf_token"])

    trainer.push_to_hub(
        repo_id=CFG["hub_model_id"],
        commit_message="Add fine-tuned RoBERTa fake-news model",
    )
    tokenizer.push_to_hub(CFG["hub_model_id"])
    print("Done! Model is live at:")
    print(f"  https://huggingface.co/{CFG['hub_model_id']}")
else:
    print("Hub push skipped — set hub_model_id and HF_TOKEN to enable.")

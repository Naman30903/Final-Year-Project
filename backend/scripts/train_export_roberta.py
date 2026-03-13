import argparse
import os

import numpy as np
import pandas as pd
import torch
from datasets import Dataset
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from sklearn.model_selection import train_test_split
from transformers import (
    AutoModelForSequenceClassification,
    AutoTokenizer,
    DataCollatorWithPadding,
    Trainer,
    TrainingArguments,
)


def parse_args():
    parser = argparse.ArgumentParser(description="Train and export RoBERTa fake-news model")
    parser.add_argument("--dataset", required=True, help="Path to CSV dataset")
    parser.add_argument("--text-col", default="text", help="Text column name")
    parser.add_argument("--label-col", default="label", help="Label column name")
    parser.add_argument("--output-dir", default="model", help="Output model directory")
    parser.add_argument("--model-name", default="roberta-base", help="Base HF model")
    parser.add_argument("--max-length", type=int, default=384)
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--lr", type=float, default=1e-5)
    parser.add_argument("--balance", action="store_true", help="Downsample to balanced classes")
    return parser.parse_args()


def compute_metrics(eval_pred):
    logits, labels = eval_pred
    preds = np.argmax(logits, axis=-1)
    acc = accuracy_score(labels, preds)
    precision, recall, f1, _ = precision_recall_fscore_support(labels, preds, average="binary")
    return {
        "accuracy": acc,
        "precision": precision,
        "recall": recall,
        "f1": f1,
    }


def main():
    args = parse_args()

    if not os.path.exists(args.dataset):
        raise FileNotFoundError(f"Dataset not found: {args.dataset}")

    df = pd.read_csv(args.dataset)
    if args.text_col not in df.columns or args.label_col not in df.columns:
        raise ValueError(f"CSV must contain columns: {args.text_col}, {args.label_col}")

    df = df[[args.text_col, args.label_col]].dropna().copy()
    df[args.text_col] = df[args.text_col].astype(str)
    df[args.label_col] = df[args.label_col].astype(int)

    # Expected mapping (same as your notebook): 0=FAKE, 1=REAL
    unique_labels = sorted(df[args.label_col].unique().tolist())
    if unique_labels != [0, 1]:
        raise ValueError(f"Labels must be 0/1. Found: {unique_labels}")

    if args.balance:
        fake_df = df[df[args.label_col] == 0]
        real_df = df[df[args.label_col] == 1]
        min_count = min(len(fake_df), len(real_df))
        df = pd.concat([
            fake_df.sample(min_count, random_state=42),
            real_df.sample(min_count, random_state=42),
        ]).sample(frac=1, random_state=42)

    train_df, val_df = train_test_split(
        df,
        test_size=0.2,
        random_state=42,
        stratify=df[args.label_col],
    )

    tokenizer = AutoTokenizer.from_pretrained(args.model_name)

    train_ds = Dataset.from_pandas(train_df.rename(columns={args.text_col: "text", args.label_col: "label"}), preserve_index=False)
    val_ds = Dataset.from_pandas(val_df.rename(columns={args.text_col: "text", args.label_col: "label"}), preserve_index=False)

    def tokenize_fn(batch):
        return tokenizer(batch["text"], truncation=True, max_length=args.max_length)

    train_ds = train_ds.map(tokenize_fn, batched=True)
    val_ds = val_ds.map(tokenize_fn, batched=True)

    model = AutoModelForSequenceClassification.from_pretrained(args.model_name, num_labels=2)

    training_args = TrainingArguments(
        output_dir="./tmp-training",
        learning_rate=args.lr,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=args.batch_size,
        num_train_epochs=args.epochs,
        weight_decay=0.01,
        eval_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="f1",
        greater_is_better=True,
        logging_steps=50,
        report_to="none",
        fp16=torch.cuda.is_available(),
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_ds,
        eval_dataset=val_ds,
        tokenizer=tokenizer,
        data_collator=DataCollatorWithPadding(tokenizer=tokenizer),
        compute_metrics=compute_metrics,
    )

    trainer.train()
    metrics = trainer.evaluate()
    print("Validation metrics:", metrics)

    os.makedirs(args.output_dir, exist_ok=True)
    trainer.model.save_pretrained(args.output_dir)
    tokenizer.save_pretrained(args.output_dir)

    print(f"Saved model artifacts to: {args.output_dir}")
    print("Expected files include config.json, model weights, tokenizer files.")


if __name__ == "__main__":
    main()

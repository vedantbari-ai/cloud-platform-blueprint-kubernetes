# GCP GKE Bootstrap Deployment

This directory contains the Terragrunt configurations responsible for deploying the initial bootstrap resources for a GCP GKE environment. Specifically, it creates:

- A Google Cloud Storage (GCS) bucket to store Terraform state files.
- A Google Cloud KMS Key Ring and Crypto Key for encrypting the Terraform state in the GCS bucket.
- Enables necessary GCP APIs (`compute`, `container`, `storage`, `file`, `cloudkms`).

This setup ensures that your Terraform state is stored securely, versioned, and encrypted, providing a robust foundation for your infrastructure deployments.

## Structure

- `clients/client-a/dev/terragrunt.hcl`: The Terragrunt configuration for `client-a` in the `dev` environment, referencing the shared Terraform module.
- `../02-modules/01-bootstrap`: The actual Terraform module that defines the GCS bucket and KMS key resources.

## Prerequisites

Before proceeding, ensure you have the following:

1.  **GCP Project**: A Google Cloud Project with billing enabled.
2.  **`gcloud` CLI**: Installed and authenticated to your target GCP project.
    ```bash
    gcloud config set project your-gcp-project-id
    gcloud auth application-default login # If running locally without a service account
    ```
3.  **Terraform**: Version `>= 1.6.0` installed.
4.  **Terragrunt**: Installed.
5.  **Permissions**: Your authenticated GCP identity must have permissions to:
    *   Enable APIs (`Service Usage Admin` role).
    *   Create GCS buckets (`Storage Admin` role).
    *   Create KMS Key Rings and Crypto Keys (`Cloud KMS Admin` role).
    *   Grant IAM roles (`Project IAM Admin` role).

## Configuration

1.  **Update `dev.yaml`**: Review and update the `gcp-gke/12-platform-config/clients/client-a/infra/dev.yaml` file.
    *   Set `gcp.project_id` to your actual GCP Project ID.
    *   Adjust `gcp.region` and `gcp.zones` as needed.
    *   Optionally, customize `bootstrap.key_ring_name` and `bootstrap.crypto_key_name`.

## Deployment Steps

This bootstrap phase is unique because the remote state backend (the GCS bucket) does not exist *before* this module is applied. Therefore, Terragrunt will initially use a local backend. After the GCS bucket is created, you will migrate the state to the newly created remote backend.

1.  **Navigate to the Terragrunt deployment directory**:
    ```bash
    cd gcp-gke/01-bootstrap/clients/client-a/dev
    ```

2.  **Initialize Terragrunt (Local Backend)**:
    Run `terragrunt init`. Terragrunt will detect that no remote state is configured in this `terragrunt.hcl` (or its parent `root.hcl` for this specific phase) and will default to a local backend.
    ```bash
    terragrunt init
    ```

3.  **Review the plan**:
    ```bash
    terragrunt plan
    ```
    Carefully review the resources that will be created: several GCP APIs, a GCS bucket, a KMS key ring, a KMS crypto key, and an IAM binding for GCS to use the KMS key.

4.  **Apply the configuration**:
    ```bash
    terragrunt apply
    ```
    Confirm with `yes` when prompted.

5.  **Migrate Local State to GCS Backend**:
    Once the `terragrunt apply` is successful and the GCS bucket has been created, you need to migrate the local Terraform state to this new remote backend.

    *   **Important**: For subsequent modules in `03-live`, the `gcp-gke/03-live/terragrunt.hcl` will automatically configure the GCS backend. However, for this initial bootstrap, we need to explicitly tell Terragrunt to use the newly created bucket.

    To do this, you will temporarily add a `remote_state` block to `gcp-gke/01-bootstrap/clients/client-a/dev/terragrunt.hcl` *or* define it in a parent `terragrunt.hcl` within the `01-bootstrap` folder that is included. For simplicity, let's assume you'll add it directly to the `dev/terragrunt.hcl` for this one-time migration.

    Add the following `remote_state` block to `gcp-gke/01-bootstrap/clients/client-a/dev/terragrunt.hcl` (after the `terraform {}` block):
    ```hcl
    remote_state {
      backend = "gcs"
      config = {
        bucket  = "nuclesteq-gcp-tf-state-${include.root.locals.config.client.name}-${include.root.locals.config.environment}"
        prefix  = "bootstrap" # Or any desired prefix for the bootstrap state
        project = include.root.locals.config.gcp.project_id
      }
    }
    ```
    Then, run the migration command:
    ```bash
    terragrunt init -migrate-state
    ```
    Terragrunt will prompt you to confirm the migration. After this, your Terraform state for the bootstrap module will be securely stored in the GCS bucket.

## Verification

You can verify the creation of resources using the `gcloud` CLI:

*   **GCS Bucket**:
    ```bash
    gcloud storage buckets describe nuclesteq-gcp-tf-state-client-a-dev
    ```
*   **KMS Key Ring**:
    ```bash
    gcloud kms key-rings describe terraform-state-keyring --location=us-central1 --project=your-gcp-project-id
    ```
*   **KMS Crypto Key**:
    ```bash
    gcloud kms keys describe terraform-state-key --keyring=terraform-state-keyring --location=us-central1 --project=your-gcp-project-id
    ```

## Cleanup

To destroy the bootstrap resources (GCS bucket and KMS key), navigate back to the `gcp-gke/01-bootstrap/clients/client-a/dev` directory and run:

```bash
terragrunt destroy
```

**Warning**: The GCS bucket has `force_destroy = false` by default in the module, meaning it must be empty before it can be destroyed. If you have manually uploaded any objects, you'll need to delete them first. If `force_destroy` was set to `true` in your `dev.yaml` (or directly in the module), all objects would be deleted automatically.

After destruction, you may want to remove the `remote_state` block from `gcp-gke/01-bootstrap/clients/client-a/dev/terragrunt.hcl` to revert it to its initial local-backend-only state for future re-deployments.
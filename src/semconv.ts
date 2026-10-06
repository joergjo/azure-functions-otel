// Copied from @opentelemetry/semantic-conventions/incubating.
// See https://github.com/open-telemetry/opentelemetry-js/tree/main/semantic-conventions#unstable-semconv

/**
 * A boolean that is true if the serverless function is executed for the first time (aka cold-start).
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_COLDSTART = 'faas.coldstart' as const;

/**
 * A string containing the schedule period as [Cron Expression](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm).
 *
 * @example "0/5 * * * ? *"
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_CRON = 'faas.cron' as const;

/**
 * The name of the source on which the triggering operation was performed. For example, in Cloud Storage or S3 corresponds to the bucket name, and in Cosmos DB to the database name.
 *
 * @example myBucketName
 * @example myDbName
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_DOCUMENT_COLLECTION =
    'faas.document.collection' as const;

/**
 * The document name/table subjected to the operation. For example, in Cloud Storage or S3 is the name of the file, and in Cosmos DB the table name.
 *
 * @example myFile.txt
 * @example myTableName
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_DOCUMENT_NAME = 'faas.document.name' as const;

/**
 * Describes the type of the operation that was performed on the data.
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_DOCUMENT_OPERATION = 'faas.document.operation' as const;

/**
 * Enum value "delete" for attribute {@link ATTR_FAAS_DOCUMENT_OPERATION}.
 *
 * When an object is deleted.
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_DOCUMENT_OPERATION_VALUE_DELETE = 'delete' as const;

/**
 * Enum value "edit" for attribute {@link ATTR_FAAS_DOCUMENT_OPERATION}.
 *
 * When an object is modified.
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_DOCUMENT_OPERATION_VALUE_EDIT = 'edit' as const;

/**
 * Enum value "insert" for attribute {@link ATTR_FAAS_DOCUMENT_OPERATION}.
 *
 * When a new object is created.
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_DOCUMENT_OPERATION_VALUE_INSERT = 'insert' as const;

/**
 * A string containing the time when the data was accessed in the [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) format expressed in [UTC](https://www.w3.org/TR/NOTE-datetime).
 *
 * @example "2020-01-23T13:47:06Z"
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_DOCUMENT_TIME = 'faas.document.time' as const;

/**
 * The execution environment ID as a string, that will be potentially reused for other invocations to the same function/function version.
 *
 * @example 2021/06/28/[$LATEST]2f399eb14537447da05ab2a2e39309de
 *
 * @note - **AWS Lambda:** Use the (full) log stream name.
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_INSTANCE = 'faas.instance' as const;

/**
 * The invocation ID of the current function invocation.
 *
 * @example "af9d5aa4-a685-4c5f-a22b-444f80b3cc28"
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_INVOCATION_ID = 'faas.invocation_id' as const;

/**
 * The name of the invoked function.
 *
 * @example "my-function"
 *
 * @note **SHOULD** be equal to the `faas.name` resource attribute of the invoked function.
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_INVOKED_NAME = 'faas.invoked_name' as const;

/**
 * The cloud provider of the invoked function.
 *
 * @note **SHOULD** be equal to the `cloud.provider` resource attribute of the invoked function.
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_INVOKED_PROVIDER = 'faas.invoked_provider' as const;

/**
 * Enum value "alibaba_cloud" for attribute {@link ATTR_FAAS_INVOKED_PROVIDER}.
 *
 * Alibaba Cloud
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_INVOKED_PROVIDER_VALUE_ALIBABA_CLOUD =
    'alibaba_cloud' as const;

/**
 * Enum value "aws" for attribute {@link ATTR_FAAS_INVOKED_PROVIDER}.
 *
 * Amazon Web Services
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_INVOKED_PROVIDER_VALUE_AWS = 'aws' as const;

/**
 * Enum value "azure" for attribute {@link ATTR_FAAS_INVOKED_PROVIDER}.
 *
 * Microsoft Azure
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_INVOKED_PROVIDER_VALUE_AZURE = 'azure' as const;

/**
 * Enum value "gcp" for attribute {@link ATTR_FAAS_INVOKED_PROVIDER}.
 *
 * Google Cloud Platform
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_INVOKED_PROVIDER_VALUE_GCP = 'gcp' as const;

/**
 * Enum value "tencent_cloud" for attribute {@link ATTR_FAAS_INVOKED_PROVIDER}.
 *
 * Tencent Cloud
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_INVOKED_PROVIDER_VALUE_TENCENT_CLOUD =
    'tencent_cloud' as const;

/**
 * The cloud region of the invoked function.
 *
 * @example "eu-central-1"
 *
 * @note **SHOULD** be equal to the `cloud.region` resource attribute of the invoked function.
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_INVOKED_REGION = 'faas.invoked_region' as const;

/**
 * The amount of memory available to the serverless function converted to Bytes.
 *
 * @example 134217728
 *
 * @note It's recommended to set this attribute since e.g. too little memory can easily stop a Java AWS Lambda function from working correctly. On AWS Lambda, the environment variable `AWS_LAMBDA_FUNCTION_MEMORY_SIZE` provides this information (which must be multiplied by 1,048,576).
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_MAX_MEMORY = 'faas.max_memory' as const;

/**
 * The name of the single function that this runtime instance executes.
 *
 * @example my-function
 * @example myazurefunctionapp/some-function-name
 *
 * @note This is the name of the function as configured/deployed on the FaaS
 * platform and is usually different from the name of the callback
 * function (which may be stored in the
 * [`code.namespace`/`code.function.name`](/docs/general/attributes.md#source-code-attributes)
 * span attributes).
 *
 * For some cloud providers, the above definition is ambiguous. The following
 * definition of function name **MUST** be used for this attribute
 * (and consequently the span name) for the listed cloud providers/products:
 *
 *   - **Azure:**  The full name `<FUNCAPP>/<FUNC>`, i.e., function app name
 *     followed by a forward slash followed by the function name (this form
 *     can also be seen in the resource JSON for the function).
 *     This means that a span attribute **MUST** be used, as an Azure function
 *     app can host multiple functions that would usually share
 *     a TracerProvider (see also the `cloud.resource_id` attribute).
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_NAME = 'faas.name' as const;

/**
 * A string containing the function invocation time in the [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) format expressed in [UTC](https://www.w3.org/TR/NOTE-datetime).
 *
 * @example "2020-01-23T13:47:06Z"
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_TIME = 'faas.time' as const;

/**
 * Type of the trigger which caused this function invocation.
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_TRIGGER = 'faas.trigger' as const;

/**
 * Enum value "datasource" for attribute {@link ATTR_FAAS_TRIGGER}.
 *
 * A response to some data source operation such as a database or filesystem read/write
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_TRIGGER_VALUE_DATASOURCE = 'datasource' as const;

/**
 * Enum value "http" for attribute {@link ATTR_FAAS_TRIGGER}.
 *
 * To provide an answer to an inbound HTTP request
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_TRIGGER_VALUE_HTTP = 'http' as const;

/**
 * Enum value "other" for attribute {@link ATTR_FAAS_TRIGGER}.
 *
 * If none of the others apply
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_TRIGGER_VALUE_OTHER = 'other' as const;

/**
 * Enum value "pubsub" for attribute {@link ATTR_FAAS_TRIGGER}.
 *
 * A function is set to be executed when messages are sent to a messaging system
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_TRIGGER_VALUE_PUBSUB = 'pubsub' as const;

/**
 * Enum value "timer" for attribute {@link ATTR_FAAS_TRIGGER}.
 *
 * A function is scheduled to be executed regularly
 *
 * @experimental This enum value is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const FAAS_TRIGGER_VALUE_TIMER = 'timer' as const;

/**
 * The immutable version of the function being executed.
 *
 * @example 26
 * @example pinkfroid-00002
 *
 * @note Depending on the cloud provider and platform, use:
 *
 *   - **AWS Lambda:** The [function version](https://docs.aws.amazon.com/lambda/latest/dg/configuration-versions.html)
 *     (an integer represented as a decimal string).
 *   - **Google Cloud Run (Services):** The [revision](https://cloud.google.com/run/docs/managing/revisions)
 *     (i.e., the function name plus the revision suffix).
 *   - **Google Cloud Functions:** The value of the
 *     [`K_REVISION` environment variable](https://cloud.google.com/run/docs/container-contract#services-env-vars).
 *   - **Azure Functions:** Not applicable. Do not set this attribute.
 *
 * @experimental This attribute is experimental and is subject to breaking changes in minor releases of `@opentelemetry/semantic-conventions`.
 */
export const ATTR_FAAS_VERSION = 'faas.version' as const;

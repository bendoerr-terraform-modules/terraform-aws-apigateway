package test_test

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/random"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/kr/pretty"
)

func TestDefaults(t *testing.T) {
	// Setup terratest
	rootFolder := "../"
	terraformFolderRelativeToRoot := "examples/simple"

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		NoColor:      os.Getenv("CI") == "true",
		Vars: map[string]interface{}{
			"namespace": strings.ToLower(random.UniqueId()),
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Print out the Terraform Output values
	_, _ = pretty.Print(terraform.OutputAll(t, terraformOptions))

	// AWS Session
	_, err := config.LoadDefaultConfig(
		t.Context(),
		config.WithRegion("us-east-1"),
	)

	if err != nil {
		t.Fatal(err)
	}

	// Get the API Gateway endpoint URL from the Terraform outputs
	apiURL := terraform.Output(t, terraformOptions, "api_invoke_url")
	t.Logf("API Gateway URL: %s", apiURL)

	// Test the API Gateway endpoint
	client := &http.Client{
		Timeout: time.Second * 30,
	}

	resp, err := client.Get(apiURL)
	if err != nil {
		t.Fatalf("Failed to make request to API Gateway: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status code %d, got %d", http.StatusOK, resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("Failed to read response body: %v", err)
	}

	// Parse response JSON
	var responseData map[string]interface{}
	if err := json.Unmarshal(body, &responseData); err != nil {
		t.Fatalf("Failed to parse response JSON: %v", err)
	}

	t.Logf("Response from API Gateway: %v", responseData)

	// Validate the response message from the Lambda handler
	if message, ok := responseData["message"]; !ok {
		t.Errorf("Response missing 'message' field")
	} else if messageStr, ok := message.(string); !ok {
		t.Errorf("'message' field is not a string: %v", message)
	} else if messageStr != "Hello from Lambda!" {
		t.Errorf("Expected message 'Hello from Lambda!', got '%s'", messageStr)
	}
}

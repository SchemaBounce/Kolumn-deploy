//go:build integration || e2e || performance || regression

// Package testing provides examples of different test types for Kolumn
package testing

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/schemabounce/kolumn/internal/testing"
)

// Example 1: Unit Test for Data Object Validation
func TestDataObjectValidation(t *testing.T) {
	tests := []struct {
		name        string
		dataObject  map[string]interface{}
		shouldError bool
		errorMsg    string
	}{
		{
			name: "valid data object",
			dataObject: map[string]interface{}{
				"name":        "Users",
				"description": "User table schema",
				"columns": map[string]interface{}{
					"id": map[string]interface{}{
						"type":        "INTEGER",
						"primary_key": true,
					},
					"email": map[string]interface{}{
						"type":     "VARCHAR(255)",
						"nullable": false,
						"unique":   true,
					},
				},
			},
			shouldError: false,
		},
		{
			name: "missing required column type",
			dataObject: map[string]interface{}{
				"name": "Invalid",
				"columns": map[string]interface{}{
					"id": map[string]interface{}{
						"primary_key": true,
						// Missing type
					},
				},
			},
			shouldError: true,
			errorMsg:    "column type is required",
		},
		{
			name: "invalid column type",
			dataObject: map[string]interface{}{
				"name": "Invalid",
				"columns": map[string]interface{}{
					"id": map[string]interface{}{
						"type": "INVALID_TYPE",
					},
				},
			},
			shouldError: true,
			errorMsg:    "invalid column type",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Example validation logic
			err := validateDataObject(tt.dataObject)

			if tt.shouldError {
				assert.Error(t, err)
				if tt.errorMsg != "" {
					assert.Contains(t, err.Error(), tt.errorMsg)
				}
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

// Example 2: Integration Test for HCL Configuration

func TestHCLConfigurationIntegration(t *testing.T) {
	helper := testing.NewTestHelper(t)
	defer helper.Cleanup()

	helper.SkipIfNoBinary()

	config := `
create "kolumn_data_object" "users" {
  name        = "User Schema"
  description = "User table with PII protection"
  
  column "id" {
    type        = "BIGINT"
    nullable    = false
    primary_key = true
  }
  
  column "email" {
    type            = "VARCHAR(255)"
    nullable        = false
    unique          = true
    classifications = ["pii"]
  }
  
  column "created_at" {
    type    = "TIMESTAMP"
    default = "CURRENT_TIMESTAMP"
  }
}

create "postgres_table" "users" {
  dynamic "column" {
    for_each = kolumn_data_object.users.columns
    content {
      name        = column.value.name
      type        = column.value.type
      nullable    = column.value.nullable
      primary_key = column.value.primary_key
      unique      = column.value.unique
      default     = column.value.default
    }
  }
}`

	configPath := helper.CreateKolumnConfig("main.kl", config)

	// Test configuration validation
	result := helper.RunKolumnCommand("validate", "-config", configPath)
	helper.AssertCommandSuccess(result)

	// Test plan generation
	planResult := helper.RunKolumnCommand("plan", "-config", configPath)
	helper.AssertCommandSuccess(planResult)
	helper.AssertOutputContains(planResult, "kolumn_data_object.users")
	helper.AssertOutputContains(planResult, "postgres_table.users")
}

// Example 3: E2E Test for Complete Workflow

func TestCompleteWorkflowE2E(t *testing.T) {
	helper := testing.NewTestHelper(t)
	defer helper.Cleanup()

	helper.SkipIfNoBinary()

	// Step 1: Initialize project
	initResult := helper.RunKolumnCommand("init", "--template", "minimal")
	helper.AssertCommandSuccess(initResult)
	helper.AssertOutputContains(initResult, "Project initialized")

	// Step 2: Create configuration
	config := `
provider "postgres" "local" {
  host     = "localhost"
  port     = 5432
  database = "test"
  username = "test"
  password = "test"
}

create "kolumn_data_object" "simple" {
  name = "Simple Schema"
  
  column "id" {
    type        = "INTEGER"
    primary_key = true
  }
  
  column "name" {
    type     = "VARCHAR(100)"
    nullable = false
  }
}

create "postgres_table" "test_table" {
  provider = postgres.local
  
  dynamic "column" {
    for_each = kolumn_data_object.simple.columns
    content {
      name        = column.value.name
      type        = column.value.type
      primary_key = column.value.primary_key
      nullable    = column.value.nullable
    }
  }
}`

	configPath := helper.CreateKolumnConfig("main.kl", config)

	// Step 3: Validate configuration
	validateResult := helper.RunKolumnCommand("validate", "-config", configPath)
	helper.AssertCommandSuccess(validateResult)

	// Step 4: Generate plan
	planResult := helper.RunKolumnCommand("plan", "-config", configPath)
	helper.AssertCommandSuccess(planResult)
	helper.AssertOutputContains(planResult, "test_table")

	// Step 5: Format configuration
	fmtResult := helper.RunKolumnCommand("fmt", "-config", configPath)
	helper.AssertCommandSuccess(fmtResult)
}

// Example 4: Performance Benchmark Test

func BenchmarkHCLParsing(b *testing.B) {
	config := generateLargeHCLConfig(100) // 100 data objects

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		err := parseHCLConfig(config)
		if err != nil {
			b.Fatalf("HCL parsing failed: %v", err)
		}
	}
}

func BenchmarkColumnFunctions(b *testing.B) {
	// Create large column set
	columns := generateTestColumns(1000)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Benchmark column manipulation functions
		selected := selectColumns(columns, []string{"id", "name", "email"})
		merged := mergeColumns(selected, generateTestColumns(10))
		filtered := filterColumns(merged, map[string]interface{}{"nullable": false})

		if len(filtered) == 0 {
			b.Fatal("Column functions returned empty result")
		}
	}
}

func BenchmarkStateSerialization(b *testing.B) {
	state := generateLargeState(50) // 50 resources

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Benchmark state serialization
		data, err := serializeState(state)
		if err != nil {
			b.Fatalf("State serialization failed: %v", err)
		}

		// Benchmark deserialization
		_, err = deserializeState(data)
		if err != nil {
			b.Fatalf("State deserialization failed: %v", err)
		}
	}
}

// Example 5: Regression Test for Connection Overrides

func TestConnectionOverrideRegression(t *testing.T) {
	helper := testing.NewTestHelper(t)
	defer helper.Cleanup()

	helper.SkipIfNoBinary()

	// This test verifies the fix for connection override validation bug
	config := `
provider "postgres" "regional" {
  connection_pattern = "db-{region}-{env}.company.com"
  regions = ["us-east", "us-west"]
  environments = ["prod", "staging"]
  
  port = 5432
  database = "production"
}

create "kolumn_data_object" "users" {
  name = "User Schema"
  
  column "id" {
    type        = "BIGINT"
    primary_key = true
  }
  
  column "email" {
    type   = "VARCHAR(255)"
    unique = true
  }
}

create "postgres_table" "users" {
  provider = postgres.regional
  
  dynamic "column" {
    for_each = kolumn_data_object.users.columns
    content {
      name        = column.value.name
      type        = column.value.type == "BIGINT" && column.value.primary_key ? "bigserial" : column.value.type
      primary_key = column.value.primary_key
      unique      = column.value.unique
    }
  }
  
  # This previously caused a validation error
  connection_overrides = {
    "db-us-east-prod" = {
      schema = "production"
    }
    "db-us-west-staging" = {
      schema = "staging_west"
    }
  }
}`

	configPath := helper.CreateKolumnConfig("main.kl", config)

	// Should now validate successfully (regression test)
	result := helper.RunKolumnCommand("validate", "-config", configPath)
	helper.AssertCommandSuccess(result)

	// Should detect multi-connection deployment
	planResult := helper.RunKolumnCommand("plan", "-config", configPath)
	helper.AssertCommandSuccess(planResult)
	helper.AssertOutputContains(planResult, "Multi-Connection Deployment Detected")
	helper.AssertOutputContains(planResult, "Connections: 4")
}

// Example 6: Security Test
func TestSecurityValidation(t *testing.T) {
	tests := []struct {
		name         string
		config       string
		shouldSecure bool
		warnings     []string
	}{
		{
			name: "PII column without encryption",
			config: `
create "kolumn_data_object" "users" {
  column "email" {
    type            = "VARCHAR(255)"
    classifications = ["pii"]
    encrypted       = false  # Security issue
  }
}`,
			shouldSecure: false,
			warnings:     []string{"PII column without encryption"},
		},
		{
			name: "properly secured PII column",
			config: `
create "kolumn_data_object" "users" {
  column "email" {
    type            = "VARCHAR(255)"
    classifications = ["pii"]
    encrypted       = true
  }
}`,
			shouldSecure: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Example security validation
			issues := validateSecurity(tt.config)

			if tt.shouldSecure {
				assert.Empty(t, issues, "Should have no security issues")
			} else {
				assert.NotEmpty(t, issues, "Should have security issues")
				for _, warning := range tt.warnings {
					found := false
					for _, issue := range issues {
						if strings.Contains(issue, warning) {
							found = true
							break
						}
					}
					assert.True(t, found, "Should contain warning: %s", warning)
				}
			}
		})
	}
}

// Test helper functions (these would be implemented in the actual codebase)

func validateDataObject(dataObject map[string]interface{}) error {
	// Example validation logic
	columns, ok := dataObject["columns"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("columns are required")
	}

	for colName, colDef := range columns {
		colMap, ok := colDef.(map[string]interface{})
		if !ok {
			return fmt.Errorf("invalid column definition for %s", colName)
		}

		colType, hasType := colMap["type"]
		if !hasType {
			return fmt.Errorf("column type is required for %s", colName)
		}

		// Validate column type
		typeStr, ok := colType.(string)
		if !ok {
			return fmt.Errorf("column type must be string for %s", colName)
		}

		if !isValidColumnType(typeStr) {
			return fmt.Errorf("invalid column type %s for %s", typeStr, colName)
		}
	}

	return nil
}

func isValidColumnType(colType string) bool {
	validTypes := []string{
		"INTEGER", "BIGINT", "VARCHAR", "TEXT", "TIMESTAMP", "BOOLEAN",
		"DECIMAL", "FLOAT", "DOUBLE", "DATE", "TIME",
	}

	for _, valid := range validTypes {
		if strings.HasPrefix(colType, valid) {
			return true
		}
	}
	return false
}

func parseHCLConfig(config string) error {
	// Simulate HCL parsing
	time.Sleep(1 * time.Millisecond) // Simulate processing time
	if strings.Contains(config, "invalid") {
		return fmt.Errorf("invalid configuration")
	}
	return nil
}

func generateLargeHCLConfig(numObjects int) string {
	var builder strings.Builder

	for i := 0; i < numObjects; i++ {
		builder.WriteString(fmt.Sprintf(`
create "kolumn_data_object" "object_%d" {
  name = "Object %d"
  
  column "id" {
    type        = "INTEGER"
    primary_key = true
  }
  
  column "data" {
    type = "VARCHAR(255)"
  }
}
`, i, i))
	}

	return builder.String()
}

func generateTestColumns(count int) map[string]interface{} {
	columns := make(map[string]interface{})

	for i := 0; i < count; i++ {
		columnName := fmt.Sprintf("col_%d", i)
		columns[columnName] = map[string]interface{}{
			"type":     "VARCHAR(100)",
			"nullable": i%2 == 0,
		}
	}

	return columns
}

func selectColumns(columns map[string]interface{}, selected []string) map[string]interface{} {
	result := make(map[string]interface{})
	for _, name := range selected {
		if col, exists := columns[name]; exists {
			result[name] = col
		}
	}
	return result
}

func mergeColumns(cols1, cols2 map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})
	for k, v := range cols1 {
		result[k] = v
	}
	for k, v := range cols2 {
		result[k] = v
	}
	return result
}

func filterColumns(columns map[string]interface{}, filter map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})
	for name, col := range columns {
		colMap, ok := col.(map[string]interface{})
		if !ok {
			continue
		}

		match := true
		for filterKey, filterValue := range filter {
			if colMap[filterKey] != filterValue {
				match = false
				break
			}
		}

		if match {
			result[name] = col
		}
	}
	return result
}

func generateLargeState(numResources int) map[string]interface{} {
	state := map[string]interface{}{
		"version":   "1.0.0",
		"resources": make([]map[string]interface{}, numResources),
	}

	resources := state["resources"].([]map[string]interface{})
	for i := 0; i < numResources; i++ {
		resources[i] = map[string]interface{}{
			"type": "postgres_table",
			"name": fmt.Sprintf("table_%d", i),
			"attributes": map[string]interface{}{
				"columns": generateTestColumns(5),
			},
		}
	}

	return state
}

func serializeState(state map[string]interface{}) ([]byte, error) {
	// Simulate state serialization
	time.Sleep(100 * time.Microsecond)
	return []byte(fmt.Sprintf("serialized_state_%d", len(state))), nil
}

func deserializeState(data []byte) (map[string]interface{}, error) {
	// Simulate state deserialization
	time.Sleep(100 * time.Microsecond)
	return map[string]interface{}{
		"version": "1.0.0",
		"data":    string(data),
	}, nil
}

func validateSecurity(config string) []string {
	var issues []string

	// Simple security validation
	if strings.Contains(config, `classifications = ["pii"]`) && strings.Contains(config, "encrypted       = false") {
		issues = append(issues, "PII column without encryption detected")
	}

	return issues
}

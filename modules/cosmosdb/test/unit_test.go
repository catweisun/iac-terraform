package test

import (
	"encoding/json"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var name = "cosmosdb-"
var location = "eastus"
var count = 10

var tfOptions = &terraform.Options{
	TerraformDir: "./",
	Upgrade:      true,
}

func asMap(t *testing.T, jsonString string) map[string]interface{} {
	var theMap map[string]interface{}
	if err := json.Unmarshal([]byte(jsonString), &theMap); err != nil {
		t.Fatal(err)
	}
	return theMap
}

func TestTemplate(t *testing.T) {

	expectedAccountResult := asMap(t, `{
    "kind": "GlobalDocumentDB",
    "enable_automatic_failover": false,
    "enable_multiple_write_locations": false,
    "is_virtual_network_filter_enabled": false,
		"offer_type": "Standard",
    "consistency_policy": [{
      "consistency_level": "Session",
      "max_interval_in_seconds": 5,
      "max_staleness_prefix": 100
    }]
	}`)

	expectedDatabaseResult := asMap(t, `{
		"name": "iac-terraform-database1",
		"throughput": 400
	}`)

	expectedContainerResult := asMap(t, `{
    "database_name": "iac-terraform-database1",
    "name": "iac-terraform-container1",
    "partition_key_path": "/id"
	}`)

	testFixture := infratests.UnitTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		Workspace:             name + random.UniqueId(),
		PlanAssertions:        nil,
		ExpectedResourceCount: count,
		ExpectedResourceAttributeValues: infratests.ResourceDescription{
			"module.cosmosdb.azurerm_cosmosdb_account.account":            expectedAccountResult,
			"module.cosmosdb.azurerm_cosmosdb_sql_database.database[0]":   expectedDatabaseResult,
			"module.cosmosdb.azurerm_cosmosdb_sql_container.container[0]": expectedContainerResult,
		},
	}

	infratests.RunUnitTests(&testFixture)
}

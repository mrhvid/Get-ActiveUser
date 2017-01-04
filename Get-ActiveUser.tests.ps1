


Describe "This is the description" {
    Context "This is the sub-description" {
    }
}


Describe "My scenario" {

    BeforeEach {
        "I run first"
    }

    Context "My Context" {

        BeforeEach { "I run second" }

        It "Demonstrates something" {
            "I run third" | Should BeOfType System.String
        }
    }

    It "Displays 1" {
        1 | Should be 1
    }

    It -Skip "Checks the database" {
        Test-DBConnect | Should BeOfType System.Data.SqlClient.SqlConnection
    }

    It -Pending "Isn't done yet" {
    }

}





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

    It -Pending "Should be able to query remote machine" {
      $obj = Get-CimInstance -ClassName Win32_Service -Computer REMOTE -EA Stop
    }

    It "Should be a number" {
      Get-Random | Should BeOfType [int]
    }

    It "should be a word" {
        "word" | Should Be "word"
    }
    
    It 'should not be a phrase' {
        "word" | Should Not Be "phrase"
    }
    
    It 'BITS should be running' {
        Get-Service *bits* | Select-Object -Expand Name | Should Be "BITS"
    }

    It 'Windows folder should exist' {
        "C:\Windows" | Should Exist
    }

}


# tests 


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

}
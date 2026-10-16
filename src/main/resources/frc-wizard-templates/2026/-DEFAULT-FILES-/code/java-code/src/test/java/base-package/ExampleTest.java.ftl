<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement,DanglingJavadoc-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
package ${data.basePackage};

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ExampleTest
{
    // To learn more about how to write unit tests, see the
    // JUnit 5 User Guide at https://junit.org/junit5/docs/current/user-guide/
    
    @Test
    // While optional, Display Names allow for clearer test purpose & intent naming via more human-readable names
    @DisplayName("String.toLoweCase should handle mixed case and return all lower case")
    void toLowerCaseHandlesMixedCase()
    {
        assertEquals("robot", "Robot".toLowerCase());
    }
    
    @Test
    @DisplayName("2 + 2 should return 4")
    void twoPlusTwoShouldEqualFour()
    {
        assertEquals(4, 2 + 2);
    }
}

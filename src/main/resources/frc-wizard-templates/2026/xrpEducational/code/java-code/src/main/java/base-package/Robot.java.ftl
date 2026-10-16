<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage};

/**
 * The run() method is called automatically when the robot is enabled. If you change the name of
 * this class or the package after creating this project, you must also update the Main.java file in
 * the project.
 */
public class ${data.robotClassSimpleName} extends EducationalRobot
{
    /**
     * This method is run when the robot is first started up and should be used for any
     * initialization code.
     */
    public Robot() {}
    
    
    /** This method is run when the robot is enabled. */
    @Override
    public void run() {}
}

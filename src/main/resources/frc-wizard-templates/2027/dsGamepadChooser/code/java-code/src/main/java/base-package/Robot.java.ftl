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

import org.wpilib.framework.OpModeRobot;

/**
 * Demonstrates DSGamepadChooser with opmodes. The autonomous opmodes each own a different
 * DSGamepadChooser, and the teleop opmode intentionally does nothing.
 */
public class ${data.robotClassSimpleName} extends OpModeRobot {}

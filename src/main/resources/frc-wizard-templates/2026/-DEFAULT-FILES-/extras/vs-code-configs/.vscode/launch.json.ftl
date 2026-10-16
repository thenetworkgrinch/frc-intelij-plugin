<#ftl output_format="plainText" encoding="UTF-8">
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
</#compress>
{
  // Use IntelliSense to learn about possible attributes.
  // Hover to view descriptions of existing attributes.
  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [

    {
      "type": "wpilib",
      "name": "WPILib Desktop Debug",
      "request": "launch",
      "desktop": true,
    },
    {
      "type": "wpilib",
      "name": "WPILib roboRIO Debug",
      "request": "launch",
      "desktop": false,
    }
  ]
}
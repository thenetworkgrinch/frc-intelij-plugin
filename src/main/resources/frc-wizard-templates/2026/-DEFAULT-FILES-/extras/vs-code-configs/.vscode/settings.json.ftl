<#ftl output_format="plainText" encoding="UTF-8">
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
</#compress>
{
  "java.configuration.updateBuildConfiguration": "automatic",
  "java.server.launchMode": "Standard",
  "files.exclude": {
    "**/.git": true,
    "**/.svn": true,
    "**/.hg": true,
    "**/CVS": true,
    "**/.DS_Store": true,
    "bin/": true,
    "**/.classpath": true,
    "**/.project": true,
    "**/.settings": true,
    "**/.factorypath": true,
    "**/*~": true
  },
<#if data.isRomiTemplate() || data.isXrpTemplate()>
  "wpilib.skipSelectSimulateExtension": true,
</#if>
  "java.test.config": [
    {
<#noparse>
      "name": "WPIlibUnitTests",
      "workingDirectory": "${workspaceFolder}/build/jni/release",
      "vmargs": [ "-Djava.library.path=${workspaceFolder}/build/jni/release" ],
      "env": {
        "LD_LIBRARY_PATH": "${workspaceFolder}/build/jni/release" ,
        "DYLD_LIBRARY_PATH": "${workspaceFolder}/build/jni/release"
</#noparse>
      }
    },
  ],
  "java.test.defaultConfig": "WPIlibUnitTests",
  "java.import.gradle.annotationProcessing.enabled": false,
  "java.completion.favoriteStaticMembers": [
    "org.junit.Assert.*",
    "org.junit.Assume.*",
    "org.junit.jupiter.api.Assertions.*",
    "org.junit.jupiter.api.Assumptions.*",
    "org.junit.jupiter.api.DynamicContainer.*",
    "org.junit.jupiter.api.DynamicTest.*",
    "org.mockito.Mockito.*",
    "org.mockito.ArgumentMatchers.*",
    "org.mockito.Answers.*",
    "edu.wpi.first.units.Units.*"
  ]<#if data.isRoboRioRobotTemplate() || data.isRomiTemplate() || data.isXrpTemplate()>,
  "java.completion.filteredTypes": [
    "java.awt.*",
    "com.sun.*",
    "sun.*",
    "jdk.*",
    "org.graalvm.*",
    "io.micrometer.shaded.*",
    "java.beans.*",
    "java.util.Base64.*",
    "java.util.Timer",
    "java.sql.*",
    "javax.swing.*",
    "javax.management.*",
    "javax.smartcardio.*",
    "edu.wpi.first.math.proto.*",
    "edu.wpi.first.math.**.proto.*",
    "edu.wpi.first.math.**.struct.*",
  ]</#if>,
  "java.dependency.enableDependencyCheckup": false
}
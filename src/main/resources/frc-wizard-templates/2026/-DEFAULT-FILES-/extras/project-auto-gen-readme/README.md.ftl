<#ftl output_format="plainText" encoding="UTF-8">
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
</#compress>
<#if data.frcWizardTemplateDefinition.isExample()>
#   Example Robot: ${data.frcWizardTemplateDefinition.displayName}
<#else>
#  ${data.frcWizardTemplateDefinition.displayName}
</#if>

${data.frcWizardTemplateDefinition.templateDescriptionInMarkdownFormat()}
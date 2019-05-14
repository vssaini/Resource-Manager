<%@ Control Language="C#" AutoEventWireup="true" CodeFile="BooleanAttributeControl.ascx.cs" Inherits="SchedulerTemplatesCS.BooleanAttributeControl" %>

<%--
	This is a simple custom control used for editing boolean custom attributes.
	It contains only a label and a check-box.
	
	Additional validation logic or styling may be applied in accordance to the type
	of the edited attribute.
--%>

<asp:CheckBox
	runat="server" ID="AttributeValue"
	Checked='<%# Convert.ToBoolean(Value) %>'
	Text='<%# Label %>'
	CssClass="rsAdvInput" />

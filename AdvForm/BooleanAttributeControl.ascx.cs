using System;
using System.Web.UI;
using System.ComponentModel;

namespace SchedulerTemplatesCS
{
	public partial class BooleanAttributeControl : UserControl
	{
		[Bindable(BindableSupport.Yes, BindingDirection.TwoWay)]
		public string Value
		{
			get
			{
				return AttributeValue.Checked.ToString();
			}

			set
			{
				if (string.IsNullOrEmpty(value))
				{
					AttributeValue.Checked = false;
				}
				else
				{
					AttributeValue.Checked = Convert.ToBoolean(value);
				}
			}
		}

		[Bindable(BindableSupport.Yes, BindingDirection.OneWay)]
		public string Label
		{
			get
			{
				return AttributeValue.Text;
			}

			set
			{
				AttributeValue.Text = value;
			}
		}


		protected void Page_Load(object sender, EventArgs e)
		{

		}
	}
}
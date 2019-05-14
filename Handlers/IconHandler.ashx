<%@ WebHandler Language="C#" Class="IconHandler" %>

using System;
using System.Linq;
using System.Web;

public class IconHandler : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        var key = context.Request.QueryString["key"] ?? context.Request["key"];
        if (key == null) return;

        // Get photo column bytes
        var resAttrID = Convert.ToInt32(key);

        var records = from c in Utility.EssResourceAttribute
                      where c.ResourceAttributeID.Equals(resAttrID)
                      select c.ImageIcon;

        var imgBytes = records.FirstOrDefault();
        if (imgBytes == null) return;

        // Send these bytes as binary image type
        context.Response.ContentType = "image/jpeg";
        context.Response.AddHeader("Cache-Control", "private,must-revalidate,post-check=1,pre-check=2,no-cache");
        context.Response.BinaryWrite(imgBytes);
    }

    public bool IsReusable
    {
        get
        {
            return true;
        }
    }

}

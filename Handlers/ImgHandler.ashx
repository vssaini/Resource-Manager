<%@ WebHandler Language="C#" Class="ImgHandler" %>

using System;
using System.Linq;
using System.Web;

public class ImgHandler : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        var key = context.Request.QueryString["key"] ?? context.Request["key"];
        if (key == null) return;

        // Get photo column bytes
        var resKey = Convert.ToInt32(key);

        var records = from c in Utility.EssResources
                      where c.ResourceID.Equals(resKey)
                      select c.Photo;

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
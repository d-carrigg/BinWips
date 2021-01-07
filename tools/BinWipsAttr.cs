using System;

namespace BinWips {
    [AttributeUsage(AttributeTargets.Assembly)]
    public class BinWipsAttribute : Attribute {
        public string Version {get;set;}
        public BinWipsAttribute(){}
        public BinWipsAttribute(string version){Version = version;}
    }
}

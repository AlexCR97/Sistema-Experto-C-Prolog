using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class SistemaOperativo : StringEnum
    {
        public static readonly SistemaOperativo Android = new SistemaOperativo("Android");
        public static readonly SistemaOperativo IOS = new SistemaOperativo("iOS");
        public static readonly SistemaOperativo Linux = new SistemaOperativo("Linux");
        public static readonly SistemaOperativo MacOS = new SistemaOperativo("MacOS");
        public static readonly SistemaOperativo Windows = new SistemaOperativo("Windows");

        private SistemaOperativo(string id) : base(id) { }
    }
}

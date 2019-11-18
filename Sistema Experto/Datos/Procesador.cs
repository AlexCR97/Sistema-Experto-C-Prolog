using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class Procesador : StringEnum
    {
        public static readonly Procesador I3 = new Procesador("Intel Core i3");
        public static readonly Procesador I5 = new Procesador("Intel Core i5");
        public static readonly Procesador I7 = new Procesador("Intel Core i7");
        public static readonly Procesador I9 = new Procesador("Intel Core i9");

        private Procesador(string id) : base(id) { }
    }
}

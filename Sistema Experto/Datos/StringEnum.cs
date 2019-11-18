using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public abstract class StringEnum
    {
        private readonly string id;

        protected StringEnum(string id)
        {
            this.id = id;
        }

        public override string ToString()
        {
            return id;
        }
    }
}

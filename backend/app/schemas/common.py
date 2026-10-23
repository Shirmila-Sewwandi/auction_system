from decimal import Decimal
from typing import Annotated

from pydantic import Field

# Matches the NUMERIC(12, 2) money columns: anything wider/finer is rejected with 422 at the
# boundary instead of overflowing the DB (500) or being silently rounded.
Money = Annotated[Decimal, Field(gt=0, max_digits=12, decimal_places=2)]

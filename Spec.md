### Automatically collected context

```yaml
library:
  name: string
  version: string
  
app:
  name: string
  version: string
  build: string
  namespace: string
  
device:
  manufacturer: string
  model: string
  id: string
  # Relies on advertising info
  adTrackingEnabled: string
  advertisingId: string 
  # relies on push token
  token: string

os:
  name: string
  version: string

network:
  carrier: string
  bluetooth: bool
  wifi: bool
  cellular: bool

screen:
  width: number
  height: number

# Relies on ad support as well  
referrer:
  type: string
  
locale: string
timezone: string

# Relies on location support
location:
  city: string
  country: string
  latitide: number
  longitude: number
  speed: number 

traits:
  # Relies on location support
  address:
    city: string
    country: string
    postalCode: string
    state: string
    street: string
```
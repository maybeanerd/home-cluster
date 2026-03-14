PVC Migration Chart
==================

This chart creates PVCs and Jobs to migrate data from source PVCs to destination PVCs.

## Workflow:
1. Scale down your app (or set replicas to 0)
2. Deploy this chart with your migration values
3. Wait for the Job(s) to complete: kubectl get jobs -n <namespace>
4. Update your app to use existingClaim: <destPvc>
5. Scale up your app
6. Set enabled: false after migration to clean up

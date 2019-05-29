using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.EventSystems;

namespace SGK
{
    public class MapPlayer : MonoBehaviour
    {
        public long id;

        public NavMeshAgent agent;
        public CharacterSprite character = null;
        public int default_direction = 0;
        public GameObject currentInteractable;
        public System.Action interactCallback;

        private const float navMeshSampleDistance = 4f;
        private const float stopDistanceProportion = 0.1f;

        private Vector3 destinationPosition;

        public System.Action<bool, GameObject> onMove;
        public System.Action<Vector3> onStop;

        public float minZ = 0;
        public float maxZ = 0;


        public float rolling = 0;

        int targetDirection = 0;
        float directionDelay = 0;

        public GameObject followCharacter;
        public GameObject GetFollowCharacter
        {
            get
            {
                return followCharacter;
            }
            set
            {
                if (value == null && followCharacterSprite)
                {
                    followCharacterSprite = null;
                }
                followCharacter = value;
                FollowCharacter(character.direction);
            }
        }
        public float followOffest = 0;
        CharacterSprite followCharacterSprite;
        CharacterSprite GetFollowCharacterSprite
        {
            get
            {
                if (GetFollowCharacter)
                {
                    if (followCharacterSprite == null)
                    {
                        CharacterSprite characterSprite = followCharacter.GetComponentInChildren<CharacterSprite>();
                        if (characterSprite)
                        {
                            followCharacterSprite = characterSprite;
                        }
                    }
                    return followCharacterSprite;
                }
                else
                {
                    followCharacterSprite = null;
                    return followCharacterSprite;
                }
            }
        }
        void Awake()
        {
            if (agent == null)
            {
                agent = GetComponent<NavMeshAgent>();
            }
        }

        // Use this for initialization
        void Start()
        {
            CoordinateCorrection();
        }

        bool isTransporting = false;
        bool arrive = true;
        // Update is called once per frame
        void Update()
        {
            if (maxZ > minZ)
            {
                character.gameObject.transform.localPosition = new Vector3(0, 0, -2 * ((maxZ - gameObject.transform.position.z) / (maxZ - minZ)));
            }
            else
            {
                character.gameObject.transform.localPosition = Vector3.zero;
            }

            directionDelay += Time.deltaTime;
            if (directionDelay > rolling && directionDelay > 0.03f && character != null)
            {
                directionDelay = 0;
                if (rolling > 0)
                {
                    character.direction = (character.direction + 1) % 8;
                    targetDirection = character.direction;
                }
                else if (targetDirection != character.direction)
                {
                    int diff = targetDirection - character.direction;
                    if (diff < 0)
                    {
                        diff += 8;
                    }

                    if (diff < 4)
                    {
                        character.direction = (character.direction + 1) % 8;
                        FollowCharacter(character.direction);
                    }
                    else
                    {
                        if (character.direction == 0)
                        {
                            character.direction = 7;
                            FollowCharacter(character.direction);
                        }
                        else
                        {
                            character.direction = character.direction - 1;
                            FollowCharacter(character.direction);
                        }
                    }
                }
            }

            if (agent == null || !agent.enabled)
                return;

            if (!agent.isActiveAndEnabled)
            {
                return;
            }

            if (!agent.isOnNavMesh)
            {
                return;
            }

            float speed = agent.desiredVelocity.magnitude;

            bool isRunning = (speed > 0.1f);

            if (agent.isOnOffMeshLink)
            {
                isRunning = false;
            }

            Vector3 velocity = agent.velocity;
            if (!isRunning && currentInteractable != null)
            {
                velocity = currentInteractable.transform.position - gameObject.transform.position;
            }

            if (character)
            {
                if (character.idle != !isRunning)
                {
                    if (onMove != null)
                    {
                        onMove(!isRunning, this.gameObject);
                    }
                }
                character.idle = !isRunning;

                if (isRunning)
                {
                    UpdateDirection(velocity, !isRunning);
                }
            }

            if (!agent.pathPending && agent.remainingDistance <= agent.stoppingDistance)
            {
                if (!agent.isStopped && onStop != null)
                {
                    onStop(gameObject.transform.position);
                }
                arrive = true;
                agent.isStopped = true;
                if (currentInteractable != null)
                {
                    doInteract();
                }
            }

            if (agent.isOnOffMeshLink && isTransporting == false)
            {
                isTransporting = true;
                OffMeshLinkData data = agent.currentOffMeshLinkData;
                MapPortal portal = data.offMeshLink.gameObject.GetComponent<MapPortal>();
                if (portal != null)
                {
                    portal.Interact(gameObject);
                }
                else
                {
                    agent.CompleteOffMeshLink();
                }
            }

            if (!agent.isOnOffMeshLink)
            {
                isTransporting = false;
            }
        }

        public int Default_Direction
        {
            get { return default_direction; }
            set
            {
                if (default_direction != value)
                {
                    default_direction = value;
                    SetDirection(default_direction);
                }
            }
        }

        public void SetDirection(int direction)
        {
            targetDirection = direction;
        }

        public void UpdateDirection(Vector3 direction, bool idle)
        {
            if (character == null) { return; }

            if (direction.sqrMagnitude > 0.01f)
            {
                Vector3 a2 = character.gameObject.transform.eulerAngles;
                int angle = (int)(angle360(new Vector3(1, 0, -1), direction, new Vector3(-1, 0, -1)) - 22.5f) + (360 - (int)a2.y);
                if (angle < 0)
                {
                    angle += 360;
                }
                angle = angle % 360;
                int character_direction = 1 + (int)Mathf.Floor(angle / 45);

                if (character)
                {
                    if (character_direction > 0)
                    {
                        targetDirection = character_direction - 1;
                    }
                }
            }
            character.idle = idle;
        }

        void doInteract()
        {
            if (currentInteractable == null)
            {
                return;
            }

            MapInteractableObject[] menus = currentInteractable.GetComponents<MapInteractableObject>();
            foreach (MapInteractableObject ite in menus)
            {
                ite.Interact(gameObject);
            }

            currentInteractable = null;

            if (interactCallback != null)
            {
                System.Action act = interactCallback;
                interactCallback = null;
                act();
            }
        }

        bool waiting_for_interact = false;
        IEnumerator WaitForInteract(float delay)
        {
            waiting_for_interact = true;
            yield return new WaitForSeconds(delay);
            waiting_for_interact = false;
        }

        float angle360(Vector3 from, Vector3 to, Vector3 right)
        {
            float angle = Vector3.Angle(from, to);
            return (Vector3.Angle(right, to) > 90f) ? 360f - angle : angle;
        }

        public void Stop()
        {
            // Stop the nav mesh agent from moving the player.
            if (!agent.isStopped && onStop != null)
            {
                onStop(gameObject.transform.position);
            }

            agent.isStopped = true;
            currentInteractable = null;
            interactCallback = null;
            if (character)
            {
                character.idle = true;
            }
        }
        void FollowCharacter(int direction)
        {
            if (GetFollowCharacterSprite)
            {
                GetFollowCharacterSprite.direction = direction > 4 ? 7 : 0;
            }
            if (GetFollowCharacter)
            {
                GetFollowCharacter.transform.localPosition = new Vector3(direction > 4 ? -followOffest : followOffest, 0, 0);
                //followOffest
            }

        }

        public Vector3 MoveTo(float x, float y, float z, bool warp = false)
        {
            if (waiting_for_interact)
            {
                return gameObject.transform.position;
            }

            return MoveTo(new Vector3(x, y, z), warp);
        }

        public Vector3 MoveTo(float x, float y, float z, GameObject target)
        {
            if (waiting_for_interact)
            {
                return gameObject.transform.position;
            }

            Vector3 pos = MoveTo(new Vector3(x, y, z), false);

            if (target != null)
            {
                if (target.GetComponents<MapInteractableObject>().Length > 0)
                {
                    currentInteractable = target;
                }

                MapClickableObject[] clickableObjects = target.GetComponents<MapClickableObject>();
                if (clickableObjects != null)
                {
                    for (int i = 0; i < clickableObjects.Length; i++)
                    {
                        clickableObjects[i].OnClick(gameObject);
                    }
                }
            }
            return pos;
        }

        public Vector3 MoveTo(Vector3 worldPosition, GameObject target)
        {
            if (waiting_for_interact)
            {
                return gameObject.transform.position;
            }

            Vector3 pos = MoveTo(worldPosition, false);

            if (target != null && target.GetComponents<MapInteractableObject>().Length > 0)
            {
                currentInteractable = target;
            }

            return pos;
        }

        public Vector3 MoveTo(Vector3 worldPosition, bool warp = false)
        {
            if (waiting_for_interact)
            {
                return gameObject.transform.position;
            }

            rolling = 0;
            agent.enabled = true;
            arrive = false;
            currentInteractable = null;
            interactCallback = null;
            destinationPosition = CalcDestinationPosition(worldPosition);
            if (!warp)
            {
                agent.isStopped = false;
                if (!agent.SetDestination(destinationPosition))
                {
                    Debug.LogErrorFormat("SetDestination failed {0}", destinationPosition);
                }
            }
            else
            {
                agent.Warp(destinationPosition);
                CoordinateCorrection();
            }
            return destinationPosition;
        }

        public void CoordinateCorrection()
        {
            if (agent != null)
            {
                agent.updateRotation = false;
                agent.autoTraverseOffMeshLink = false;

                if (agent.enabled && !agent.isOnNavMesh)
                {
                    Debug.LogErrorFormat("agnet not on nav mesh");
                    NavMeshHit hit;

                    if (NavMesh.SamplePosition(transform.position, out hit, 100, NavMesh.AllAreas))
                    {
                        agent.Warp(hit.position);
                    }
                }
            }
        }
        public Vector3 Interact(string gameObjectName, System.Action callback = null)
        {
            GameObject obj = UnityEngine.GameObject.Find(gameObjectName);
            if (obj != null)
            {
                Interact(obj, callback);
                return obj.transform.position;
            }
            return transform.position;
        }

        public Vector3 Interact(GameObject gameObject, System.Action callback = null)
        {
            if (waiting_for_interact)
            {
                return gameObject.transform.position;
            }

            // if (gameObject.GetComponents<MapInteractableMenu>().Length > 0) {
            currentInteractable = gameObject;
            interactCallback = callback;
            // }

            destinationPosition = CalcDestinationPosition(gameObject.transform.position);
            arrive = false;
            agent.enabled = true;

            if (Vector3.Distance(destinationPosition, transform.position) <= agent.stoppingDistance)
            {

                if (!agent.isStopped && onStop != null)
                {
                    onStop(gameObject.transform.position);
                }

                arrive = true;
                doInteract();
                return destinationPosition;
            }

            agent.SetDestination(destinationPosition);
            agent.isStopped = false;

            return destinationPosition;
        }

        Vector3 CalcDestinationPosition(Vector3 worldPosition)
        {
            NavMeshPath path = new NavMeshPath();

            NavMesh.CalculatePath(transform.position, worldPosition, NavMesh.AllAreas, path);

            NavMeshHit hit;
            if (NavMesh.SamplePosition(worldPosition, out hit, navMeshSampleDistance, NavMesh.AllAreas))
                return hit.position;
            else
                return worldPosition;
        }

        private float m_mapPosCoeff = 20.0f;
        public Vector3 GetMapPosition()
        {
            return gameObject.transform.localPosition * m_mapPosCoeff;
        }

        public void WaitForSeconds(float delay, System.Action callback)
        {
            StartCoroutine(WaitThread(delay, callback));
        }

        IEnumerator WaitThread(float delay, System.Action callback)
        {
            yield return new WaitForSeconds(delay);
            callback();
        }

        public void WaitForArrive(System.Action callback)
        {
            StartCoroutine(WaitArrivedThread(callback));
        }

        IEnumerator WaitArrivedThread(System.Action callback)
        {
            do
            {
                yield return null;
            } while (!arrive || agent.pathPending);

            callback();
        }

        private void OnDestroy()
        {
            interactCallback = null;
            onMove = null;
            onStop = null;
        }
    }
}
